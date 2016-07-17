


cdef class Graph:

    cdef size_t default_arc_block_count(self):
        return 2 * self.default_vertex_block_count()

    cdef size_t default_vertex_block_count(self):
        return 10

    cdef size_t vertex_size(self):
        return sizeof(graph_vertex)

    cdef size_t edge_size(self):
        return sizeof(graph_edge)

    def __cinit__(self, *args, **kwargs):
        self._name = ""
        self.v_manager = None
        self.e_manager = None
        self.vertices  = NULL
        self.resources.e_manager = NULL
        self.resources.v_manager = NULL

    def __init__(self, rep=None, str name="", size_t vb_count=0, size_t eb_count=0):
        self._name = name
        if vb_count == 0:
            vb_count = self.default_vertex_block_count()
        if eb_count == 0:
            eb_count = self.default_arc_block_count()
        if rep is not None:
            if isinstance(rep, Graph):
                # TODO: change counts to match rep ???
                self._ensure_managers(vb_count, eb_count)
                copy_graph(&self.resources, (<Graph>rep).vertices, &self.vertices)
            else:
                self._ensure_managers(vb_count, eb_count)
                self.parse_rep(rep)
        else:
            self._ensure_managers(vb_count, eb_count)

    cdef void _ensure_managers(self, size_t vb_count, size_t eb_count) except *:
        cdef graph_resources *r = &self.resources
        if self.v_manager is None:
            self.v_manager = VertexManager(vb_count, size=self.vertex_size())
        if self.e_manager is None:
            self.e_manager = EdgeManager(eb_count, size=self.edge_size())
        r.e_manager = <void*>self.e_manager
        r.v_manager = <void*>self.v_manager
        r.request_edge = <f_request_edge>self.e_manager.request
        r.release_edge = <f_release_edge>self.e_manager.release
        r.request_vertex = <f_request_vertex>self.v_manager.request
        r.release_vertex = <f_release_vertex>self.v_manager.release

    property name:
        def __get__(self):
            cdef str value = self._name
            if not value:
                return "[[graph#%i]]" % id(self)
            return value

        def __set__(self, str value):
            self._name = value

    def __repr__(self):
        from pprint import saferepr
        return "%s(%s)" % (self.__class__.__name__, 
                           saferepr(self.make_rep(sort=True)))

    def __str__(self):
        cdef str jrep, s = "{ \"%s\":[" % self.name 
        cdef list irep, rep = self.make_rep(sort=True)
        from pprint import pformat
        for irep in rep:
            for jrep in pformat(irep).split('\n'):
                s += "\n    %s" % jrep
            s+=","
        s += "\n  ]\n}\n"
        return s

    cpdef size_t arc_count(self):
        cdef graph_arc *a
        cdef graph_vertex *v = self.vertices
        cdef int x = 0
        while v!=NULL:
            a = v.arcs
            while a!=NULL:
                x+=1
                a = a.next
            v = v.next
        return x

    def edge_count(self):
        return self.arc_count() / 2

    cpdef Graph ensure_edge(self, size_t u_vid, size_t v_vid):
        if u_vid == v_vid:
            return self
        ensure_edge(&self.resources, &self.vertices, u_vid, v_vid)
        return self

    cpdef Graph ensure_vertex(self, size_t vid):
        ensure_vertex(&self.resources, &self.vertices, vid)
        return self

    def v_info(self):
        cdef str s = "vertices in use: %i\n%s" % (len(self), self.v_manager)
        return s

    def e_info(self):
        cdef str s = "edges in use: %i\n%s" % (self.edge_count(), self.e_manager)
        return s

    def info(self):
        cdef str s = "%s\n%s" % (self.v_info(), self.e_info())
        return s

    def __add__(x, y):
        cdef Graph g, rg
        if isinstance(x, Graph):
            g = <Graph>x
        else:
            g = <Graph>y
            y = x
        if isinstance(y, Graph):
            rg = type(g)(g)
            if <void*>x==<void*>y:
                return rg
            copy_graph(&rg.resources, (<Graph>y).vertices, &rg.vertices)
            return rg
        elif isinstance(y, int):
            rg = type(g)(g)
            rg.ensure_vertex(y)
            return rg
        elif isinstance(y, tuple) and len(y) == 2:
            rg = type(g)(g)
            rg.ensure_edge(*y)
            return rg
        return NotImplemented

    def __iadd__(self, x):
        if isinstance(x, int):
            self.ensure_vertex(x)
            return self
        elif isinstance(x, tuple) and len(x) == 2:
            self.ensure_edge(*x)
            return self
        elif isinstance(x, Graph):
            if <void*>x == <void*> self:
                return self
            copy_graph(&self.resources, (<Graph>x).vertices, &self.vertices)
            return self
        return NotImplemented

    def __len__(self):
        cdef graph_vertex *v = self.vertices
        cdef int x = 0
        while (v!=NULL):
            x += 1
            v = v.next
        return x

    cpdef void parse_rep(self, rep) except *:
        cdef list x, crep
        cdef size_t v=0, u=0
        if isinstance(rep, basestring):
            from ast import literal_eval #safer version of eval
            crep = literal_eval(rep)
        else:
            crep = rep
        for x in crep:
            v = x[0]
            for u in <list>x[1]:
                self.ensure_edge(u, v)
            else:
                self.ensure_vertex(v)
        
    cpdef list make_rep(self, bint sort=False):
        cdef graph_vertex *v = self.vertices
        cdef graph_arc *a
        cdef list rep=[], vrep, arep
        while v!=NULL:
            a = v.arcs
            arep = []
            vrep = [v.vid, arep]
            if a == NULL:
                rep.append(vrep)
            else:
                while a!=NULL:
                    if v.vid < as_vertex(a).vid:
                        arep.append(as_vertex(a).vid)
                    a = a.next
                if len(arep):
                    if sort: arep.sort()
                    rep.append(vrep)
            v = v.next
        if sort: rep.sort()
        return rep

    #cpdef list components_from_c(self):
    #    cdef list l = []
    #    graph_components(self.vertices, <void*>l, <found_vid>add_to_list )
    #    return l



    cpdef list components(self):
        cdef graph_vertex *v = self.vertices
        cdef graph_arc    *a 
        cdef size_t order = 0
        cdef list components = []

        if v==NULL:
            return components

        # initialize order etc...

        while (v!=NULL):
            v.w0.order = 0
            v = v.next

        v = self.vertices
        while v!=NULL:

            if v.arcs==NULL:
                components.append(v.vid)
                v = v.next
                continue
            
            if v.w0.order != 0:
                v = v.next
                continue
            
            # start dfs on v
            a = v.arcs
            order += 1
            v.w0.order = order
            components.append(v.vid)
            v.w1.arcs = NULL

            while 1:
                if a!=NULL:
                    if as_vertex(a).w0.order != 0:
                        # skip already visited vertices
                        a = a.next
                        continue
                    # descend into v
                    v = as_vertex(a)
                    order += 1
                    v.w0.order = order
                    v.w1.arcs = a_cross(a)
                    a = v.arcs
                    continue
                else:
                    # backup to previous vertex
                    a = v.w1.arcs
                    if a == NULL:
                        break
                    v = as_vertex(a)
                    a = a_cross(a)
                    a = a.next
                    continue

            v = v.next

        return components

    def __getitem__(self, vid):
        #return the adjacent vertices to v
        cdef graph_vertex *v
        cdef graph_arc *a
        cdef list adj = []
        if isinstance(vid, int):
            v = find_vertex(self.vertices, vid)
            if v == NULL:
                return None
            a = v.arcs
            while a!=NULL:
                adj.append(as_vertex(a).vid)
                a = a.next
            return adj
        return None

    @classmethod
    def random_graph(cls, size_t vertices, size_t edges, *args, **kwargs):
        from random import randint
        g = cls(*args, **kwargs)
        for i in xrange(vertices):
            g += i+1
        for z in xrange(edges):
            u = randint(1, vertices)
            v = randint(1, vertices)
            while u == v:
                v = randint(1, vertices)
            g += (u,v)
        return g


#cdef void add_to_list(void *list_, size_t value):
#    (<list>list_).append(value)


cdef class TextFileTokenizer:
    def __cinit__(self, file_):
        self.lines = iter(file_)
        self.tokens = None
    def __iter__(self):
        return self
    def __next__(self):
        try:
            while 1:
                if self.tokens is None:
                    self.tokens = iter(self.lines.next().strip().split())
                try:
                    return self.tokens.next()
                except StopIteration:
                    self.tokens = None
        except StopIteration:
            raise


cpdef list parse_file(str file_name):
    #try to parse a gng text file
    #returns list of graphs
    cdef list graphs = []
    cdef Graph g
    cdef int i, v = 0
    cdef TextFileTokenizer t
    cdef object f

    with open(file_name) as f:
        t = TextFileTokenizer(f)
        while 1:
            try:
                while t.next() != "$": pass
                if t.next().lower()=="&graph":
                    g = Graph(name=t.next(), vb_count=int(t.next()))
                    i = int(t.next())
                    while i:
                        if i<0:
                            v = -i
                        else:
                            g += (v, i)
                        i = int(t.next())
                    graphs.append(g)
            except StopIteration:
                break
    return graphs









