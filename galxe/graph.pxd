
from .core cimport *

cdef class TextFileTokenizer:
    cdef object lines, tokens

cdef class Graph:
    cdef:
        graph_vertex *vertices
        str  _name
        VertexManager v_manager
        EdgeManager    e_manager
        graph_resources resources

        size_t default_vertex_block_count(self)
        size_t default_arc_block_count(self)
        size_t vertex_size(self)
        size_t edge_size(self)
        void _ensure_managers(self, size_t vcount, size_t acount) except *

    cpdef size_t arc_count(self)
    cpdef void parse_rep(self, rep) except *
    cpdef list make_rep(self, bint sort=*)
    cpdef Graph ensure_edge(self, size_t u, size_t v)
    cpdef Graph ensure_vertex(self, size_t v)
    cpdef list components(self)
 

cpdef list parse_file(str file_name)

