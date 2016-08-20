
#  Copyright 2016 Andrew Chalaturnyk
#
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# distutils: language=c
# distutils: libraries=galxe_support
# distutils: include_dirs=lib/include

from .utils cimport TextFileTokenizer
from .dfs cimport components, graph_connected

from libc.stdint cimport uintptr_t

from ast import literal_eval #safer version of eval
from pprint import pformat


cdef graph_vertex *find_vertex(void *v_container, size_t vid):
    cdef object r = (<dict>v_container).get(vid)
    if r is None:
        return NULL
    return <graph_vertex*>(<uintptr_t>r)

cdef void register_vertex(void *v_container, graph_vertex* v):
    (<dict>v_container)[v.vid] = <uintptr_t>(<void*>v)


cdef class VertexIterator:
    cdef Graph graph      #make sure iterator dies first
    cdef vertex_list *g
    cdef graph_vertex *n

    def __cinit__(self, Graph g):
        self.graph = g
        self.g = &g.vertices
        self.n = vlist_first(self.g)

    def __iter__(self):
        return self

    def __next__(self):
        cdef graph_vertex *n
        n = self.n
        if vlist_is_done(n, self.g):
            raise StopIteration()
        self.n = v_next(n)
        return n.vid


cdef class Graph:

    cdef size_t default_arc_block_count(self):
        return 2 * self.default_vertex_block_count()

    cdef size_t default_vertex_block_count(self):
        return 10

    cdef size_t vertex_size(self):
        return sizeof(graph_vertex)

    cdef size_t edge_size(self):
        return sizeof(graph_edge)

    cdef size_t vb_count(self):
        return (self.v_manager.allocator.block_size
                / self.v_manager.v_size)

    cdef size_t eb_count(self):
        return (self.e_manager.allocator.block_size
                / self.e_manager.e_size)


    def __cinit__(self, *args, **kwargs):
        self._name = ""
        self.v_manager = None
        self.e_manager = None
        self.v_container = None
        reset_graph_resources(&self.resources)
        vlist_reset(&self.vertices)
        self.resources.g = &self.vertices

    def __init__(self,
        object source=None,
        str    name="",
        size_t vb_count=0, size_t eb_count=0,
        fast_lookup=True
    ):
        cdef VertexManager vm
        cdef EdgeManager em
        cdef graph_resources *r = &self.resources

        self._name = name
        if isinstance(source, Graph):
            graph = <Graph>source
            if vb_count == 0:
                vb_count = (<Graph>source).vb_count()
            if eb_count == 0:
                eb_count = (<Graph>source).eb_count()
        if vb_count == 0:
            vb_count = self.default_vertex_block_count()
        if eb_count == 0:
            eb_count = self.default_arc_block_count()
        if fast_lookup:
            #use a python dict for now, once digraphs are
            #created, try to use a self balancing tree to lookup
            #vertices
            self.v_container = dict()

        # configure resource managers
        self.v_manager = vm = VertexManager(vb_count, size=self.vertex_size())
        self.e_manager = em = EdgeManager(eb_count, size=self.edge_size())

        r.v_manager = <void*>vm
        r.e_manager = <void*>em
        r.request_vertex = <f_request_vertex> vm.request
        r.release_vertex = <f_release_vertex> vm.release
        r.request_edge = <f_request_edge> em.request
        r.release_edge = <f_release_edge> em.release

        if self.v_container is not None:
            r.v_container = <void*>self.v_container
            r.register_vertex = <f_register_vertex> register_vertex
            r.find_vertex     = <f_find_vertex> find_vertex
        else:
            r.v_container = r.g

        # copy any source data over

        if isinstance(source, Graph):
            copy_graph(&self.resources, &(<Graph>source).vertices)
        elif isinstance(source, list):
            self.parse_repr(source)

    property name:
        def __get__(self):
            cdef str value = self._name
            if not value:
                return "[[graph#%i]]" % id(self)
            return value

        def __set__(self, str value):
            self._name = value

    def __repr__(self):
        if self._name:
            return "%s(name=%r,source=%s)" % (self.__class__.__name__,
                                   self._name,
                                   self.make_repr(sort=True))
        return "%s(%s)" % (self.__class__.__name__,
                           self.make_repr(sort=True))


    def __str__(self):
        if self._name:
            return "%s(name=%r,source=%s)" % (self.__class__.__name__,
                                       self._name,
                                       pformat(self.make_repr(sort=True)))
        return "%s(%s)" % (self.__class__.__name__,
                                   pformat(self.make_repr(sort=True)))


    cpdef size_t arc_count(self):
        cdef:
            vertex_list *g = &self.vertices
            graph_vertex *v = vlist_first(g)
            size_t count=0
        while not vlist_is_done(v,g):
            count += v_arcs_length(v)
            v = v_next(v)
        return count

    def edge_count(self):
        return self.arc_count() / 2

    cpdef Graph ensure_edge(self, size_t u_vid, size_t v_vid):
        if u_vid == v_vid:
            return self
        ensure_edge(&self.resources, u_vid, v_vid)
        return self

    cpdef Graph ensure_vertex(self, size_t vid):
        ensure_vertex(&self.resources, vid)
        return self

    def v_info(self):
        cdef str s = "vertices in use: %i\n%s" % (len(self), self.v_manager)
        return s

    def e_info(self):
        cdef str s = "edges in use: %i\n%s" % (self.edge_count(),
                                               self.e_manager)
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
            copy_graph(&rg.resources, &(<Graph>y).vertices)
            return rg
        elif isinstance(y, int):
            rg = type(g)(g)
            rg.ensure_vertex(y)
            return rg
        elif isinstance(y, tuple) and len(y) == 2:
            rg = type(g)(g)
            rg.ensure_edge(*y)
            return rg
        elif isinstance(y, list) and y:
            rg = type(g)(g)
            if not isinstance(y[0], list):
                rg += y
                return rg
            rg.parse_repr(y)
            return rg
        return NotImplemented

    cdef graph_vertex *add_list(self, list v_repr) except NULL:
        cdef object i = iter(v_repr)
        cdef graph_resources *r = &self.resources
        cdef graph_vertex    *u = ensure_vertex(r, i.next())
        try:
            while 1: ensure_edge_v(r, u, i.next())
        except StopIteration: pass
        return u

    def __iadd__(self, x):
        if isinstance(x, int):
            self.ensure_vertex(x)
            return self
        elif isinstance(x, tuple) and len(x) == 2:
            self.ensure_edge(*x)
            return self
        elif isinstance(x, list) and x:
            if not isinstance(x[0], list):
                self.add_list(x)
                return self
            self.parse_repr(x)
            return self
        elif isinstance(x, Graph):
            if <void*>x == <void*> self:
                return self
            copy_graph(&self.resources, &(<Graph>x).vertices)
            return self
        return NotImplemented

    def __len__(self):
        return vlist_length(&self.vertices)

    def __iter__(self):
        return VertexIterator(self)

    cpdef void parse_repr(self, repr_) except *:
        cdef list x, v_repr
        if isinstance(repr_, basestring):
            v_repr = literal_eval(repr_)
        elif isinstance(repr_, list):
            v_repr = repr_
        else: raise TypeError(repr_)
        for x in v_repr: self.add_list(x)

    cpdef list make_repr(self, bint sort=False):
        cdef vertex_list *g = &self.vertices
        cdef graph_vertex *v = vlist_first(g)
        cdef graph_arc *a
        cdef list repr_=[], arep
        while not vlist_is_done(v, g):
            a = v_arcs_first(v)
            if v_arcs_is_done(a,v):
                repr_.append([v.vid])
            else:
                arep = []
                while not v_arcs_is_done(a, v):
                    if a.target.vid > v.vid:
                        arep.append(a.target.vid)
                    a = a_next(a)
                if arep:
                    if sort: arep.sort()
                    arep.insert(0, v.vid)
                    repr_.append(arep)
            v = v_next(v)
        if sort: repr_.sort()
        return repr_


    def __getitem__(self, vid):
        #return the adjacent vertices to v
        cdef graph_vertex *v
        cdef graph_arc *a
        cdef list adj
        if isinstance(vid, int):
            adj = []
            v = self.resources.find_vertex(self.resources.v_container, vid)
            if v == NULL:
                return None
            a = v_arcs_first(v)
            while not v_arcs_is_done(a, v):
                adj.append(a.target.vid)
                a = a_next(a)
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

    ## see dfs.pyx for implmentation

    cpdef bint connected(self): return graph_connected(&self.vertices)
    cpdef Graph components(self): return components(self)

cpdef list parse_file(str file_name):
    #try to parse a gng text file of simple undirected graphs
    #returns list of graphs
    cdef list graphs = []
    cdef Graph g
    cdef int i, v = 0
    cdef str nm

    cdef TextFileTokenizer t
    cdef object f

    with open(file_name) as f:
        t = TextFileTokenizer(f)
        while 1:
            try:
                while t.next() != "$": pass
                if t.next().lower()=="&graph":
                    nm = t.next()
                    v  = int(t.next())
                    g = Graph(name=nm, vb_count=v)
                    # create all vertices from 1..i first for
                    # the case of a solitary vertex (slower but nessesary)
                    for i in xrange(v,0,-1): g+=i
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

cpdef size_t write_file(str file_name, list graphs, bint relabel=True):
    #write out gng style text file of simple graphs
    cdef size_t vid
    cdef str edges
    cdef graph_vertex *v
    cdef size_t c, gc=0
    cdef Graph graph
    cdef vertex_list *g
    cdef graph_arc *a

    from os.path import isfile

    if isfile(file_name):
        raise Exception("Will not overwrite existing file.")
        #TODO: different exception
    with open(file_name, "w") as f:
        for graph in graphs:
            if len(graph) != max(graph):
                if relabel:
                    #make copy of g and relabel vertices 1..|V(G)|
                    graph = type(graph)(graph,
                                        name=graph.name+"_relabeled",
                                        fast_lookup=False)
                    g = &graph.vertices
                    v = vlist_first(g)
                    c = 0
                    while not vlist_is_done(v, g):
                        c += 1
                        v.vid = c
                        v = v_next(v)
                else:
                    raise Exception("GnG graph must have vertices 1..|V(G)|")
            f.write("$\n&Graph\n%s\n%i\n" % (graph.name, len(graph)))
            gc += 1
            g = &graph.vertices
            v = vlist_first(g)
            while not vlist_is_done(v, g):
                a = v_arcs_first(v)
                edges = ""
                while not v_arcs_is_done(a, v):
                    vid = a.target.vid
                    if vid > v.vid:
                        edges += " " + str(vid)
                    a = a_next(a)
                if edges: f.write("-%i%s\n" % (v.vid, edges))
                v = v_next(v)

            f.write('0\n')
    return gc



