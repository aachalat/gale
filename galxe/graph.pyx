
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


from .utils cimport TextFileTokenizer
from .dfs cimport components, components_c

cdef class VertexIterator:
    cdef (graph_vertex *) v, n

    def __cinit__(self, Graph g):
        self.v = g.vertices

    def __iter__(self):
        return self

    def __next__(self):
        cdef graph_vertex *n
        n = self.v
        if n == NULL:
            raise StopIteration()
        self.v = n.next
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

    def __iter__(self):
        return VertexIterator(self)

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

    cpdef list components(self): return components(self)
    cpdef list components_c(self): return components_c(self)

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
    cdef Graph g

    from os.path import isfile

    if isfile(file_name):
        raise Exception("Will not overwrite existing file.")  #TODO: different exception
    with open(file_name, "w") as f:
        for g in graphs:
            if len(g) != max(g):
                if relabel:
                    #make copy of g and relabel vertices 1..|V(G)|
                    g = type(g)(g, name=g.name+"_relabeled") # maybe change block counts...
                    v = g.vertices
                    c = 0
                    while (v):
                        c +=1
                        v.vid = c
                        v = v.next
                else:
                    raise Exception("GnG graph must have vertices 1..|V(G)|")
            f.write("$\n&graph\n%s\n%i\n" % (g.name, len(g)))
            gc += 1
            for vid in g:
                edges = " ".join([str(y) for y in g[vid] if y > vid])
                if edges: f.write("-%i %s\n" % (vid, edges))
            f.write('0\n')
    return gc
