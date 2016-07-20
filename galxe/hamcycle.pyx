
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

from .core cimport (
    graph_vertex,
    graph_arc,
    arc_data,
    EdgeManager,
    graph_edge_ext,
    a_data,
    a_cross,
    as_vertex,
    find_vertex,
    find_edge_by_vid
)

from .graph cimport Graph

cdef struct hamcycle_vertex:
    graph_vertex vertex
    (graph_arc *) endpoint, removed_arcs, cycle_edge
    graph_vertex *last_anchor

cdef class HamCycleGraph(Graph):

    cdef graph_arc *detached
    cdef bint _ext_ready

    def __cinit__(self, *args, **kwargs):
        self.detached = NULL
        self._ext_ready = False

    cdef size_t vertex_size(self):
        return sizeof(hamcycle_vertex)

    cdef size_t edge_size(self):
        return sizeof(graph_edge_ext)

    cpdef size_t find_hamcycles(self):
        # first find out if graph is connected

        if not self.connected():
            return 0

        self.prep_arcs()


    cpdef prep_arcs(self):
        cdef graph_vertex *v
        cdef graph_arc    *a
        cdef graph_arc    **pn

        # prep arcs/edges for fast removal
        v = self.vertices
        while v:
            a = v.arcs
            pn = &v.arcs
            while a:
                a_data(a).w0.arc_pn = pn
                pn = &a.next
                a = a.next
            v = v.next
        self._ext_ready = True

    cpdef detach_arc(self, size_t u, size_t v):
        cdef (graph_arc *) a, na
        cdef arc_data *d
        if not self._ext_ready: return None
        a = find_edge_by_vid(self.vertices, u, v)
        if a:
            na = a.next
            d = a_data(a)
            d.w0.arc_pn[0] = a.next
            if na: a_data(na).w0.arc_pn = d.w0.arc_pn
            a.next = self.detached
            self.detached = a
            return True
        return False

    cpdef attach_arc(self, size_t count=1):
        cdef (graph_arc *) a, na, n
        cdef graph_vertex *v
        if not self._ext_ready: return None
        a = self.detached
        if not a: return None
        while count and a:
            count -= 1
            n = a.next

            v = as_vertex(a_cross(a))
            na = v.arcs
            if na: a_data(na).w0.arc_pn = &a.next
            a_data(a).w0.arc_pn = &v.arcs
            a.next = na
            v.arcs = a

            a = n
        self.detached = a
        return True

    cpdef list_detached(self):
        cdef list d = []
        a = self.detached
        while a:
            d.append((as_vertex(a_cross(a)).vid, as_vertex(a).vid))
            a = a.next
        return d









