
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


from .core cimport *

cdef class Graph:
    cdef:
        vertex_list vertices
        str  _name

        dict            v_container
        VertexManager   v_manager
        EdgeManager     e_manager

        graph_resources resources

        size_t default_vertex_block_count(self)
        size_t default_arc_block_count(self)
        size_t vertex_size(self)
        size_t edge_size(self)
        size_t vb_count(self)
        size_t eb_count(self)
    cdef graph_vertex *add_list(self, list v_repr) except NULL
    cpdef size_t arc_count(self)
    cpdef void parse_repr(self, repr) except *
    cpdef list make_repr(self, bint sort=*)
    cpdef Graph ensure_edge(self, size_t u, size_t v)
    cpdef Graph ensure_vertex(self, size_t v)

    # dfs algorithms that work with standard graph_vertex (w0,w1 defined)
    # see dfs.pyx for implementations

    cpdef Graph components(self)
    cpdef bint connected(Graph)

cpdef list parse_file(str file_name)
cpdef size_t write_file(str file_name, list graphs, bint relabel=*)

