
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

cdef extern from "graph.h":

    ctypedef void* vertex_list  #note: LIST_ENTRY_TYPE(graph_vertex)
    ctypedef void* arc_list     #note: LIST_ENTRY_TYPE(graph_arc)

    union word_aux:
        graph_vertex *vertex
        graph_arc    *arcs
        graph_arc   **ap
        arc_list     *alist
        vertex_list  *vlist
        void         *other
        size_t        order
        size_t        lowpt
        long          color

    struct graph_arc:
        graph_vertex *target
        word_aux      w0

    struct graph_vertex:
        size_t      vid
        word_aux    w0
        word_aux    w1

    struct graph_edge:
        pass

    ctypedef graph_vertex *(*f_find_vertex)(void *, size_t)
    ctypedef graph_vertex *(*f_request_vertex)(void *)
    ctypedef graph_arc *(*f_request_edge)(void *)
    ctypedef void (*f_release_vertex)(void *, graph_vertex*)
    ctypedef void (*f_release_edge)(void *, graph_arc*)
    ctypedef void (*f_register_vertex)(void *, graph_vertex*)

    struct graph_resources:
        void            *v_manager
        void            *e_manager
        void            *v_container
        vertex_list     *g
        f_release_edge    release_edge
        f_request_edge    request_edge
        f_request_vertex  request_vertex
        f_release_vertex  release_vertex
        f_find_vertex     find_vertex
        f_register_vertex register_vertex

    graph_arc    *a_cross(graph_arc *) nogil

    graph_arc    *create_edge(graph_resources*,
                              graph_vertex*,
                              graph_vertex*) except NULL
    graph_vertex *create_vertex(graph_resources*, size_t) except NULL
    graph_vertex *ensure_vertex(graph_resources*, size_t) except NULL
    graph_arc    *ensure_edge(graph_resources*, size_t, size_t) except NULL

    void copy_graph(graph_resources*, vertex_list*) except *
    void reset_graph_resources(graph_resources*) nogil
    graph_vertex *v_next(graph_vertex*) nogil
    graph_vertex *v_set_next(graph_vertex*, graph_vertex*) nogil
    graph_vertex *v_attach(graph_vertex*, graph_vertex**) nogil
    graph_vertex *v_detach(graph_vertex*) nogil
    graph_vertex **v_after(graph_vertex*) nogil
    graph_vertex **v_before(graph_vertex*) nogil

    graph_arc *a_next(graph_arc*) nogil
    graph_arc *a_set_next(graph_arc*, graph_arc*) nogil
    graph_arc *a_attach(graph_arc*, graph_arc**) nogil
    graph_arc *a_detach(graph_arc*) nogil
    graph_arc **a_after(graph_arc*) nogil
    graph_arc **a_before(graph_arc*) nogil

    graph_vertex **vlist_bottom(vertex_list*) nogil
    graph_vertex **vlist_top(vertex_list*) nogil
    bint vlist_is_done(graph_vertex*, vertex_list*) nogil
    bint vlist_is_empty(vertex_list *) nogil
    bint vlist_contains(graph_vertex *, vertex_list*) nogil
    void vlist_combine_top(vertex_list*, vertex_list*) nogil
    void vlist_combine_bottom(vertex_list*, vertex_list*) nogil
    void vlist_append_chunk_top(vertex_list*,
                                graph_vertex*,graph_vertex*) nogil
    void vlist_reset(vertex_list*) nogil
    graph_vertex *vlist_prev(graph_vertex*,vertex_list*) nogil
    void vlist_push(graph_vertex*, vertex_list*) nogil
    graph_vertex *vlist_pop(vertex_list*) nogil
    graph_vertex *vlist_first(vertex_list*) nogil
    size_t vlist_length(vertex_list*) nogil

    graph_arc **v_arcs_bottom(graph_vertex*) nogil
    graph_arc **v_arcs_top(graph_vertex*) nogil
    bint v_arcs_is_done(graph_arc*, graph_vertex*) nogil
    bint v_arcs_is_empty(graph_vertex*) nogil
    void v_arcs_reset(graph_vertex*) nogil
    graph_arc *v_arcs_first(graph_vertex*) nogil
    size_t v_arcs_length(graph_vertex*) nogil
    graph_arc *v_arcs_pop(graph_vertex*) nogil
    void v_arcs_push(graph_arc*, graph_vertex*) nogil


    graph_arc **alist_bottom(arc_list*) nogil
    graph_arc **alist_top(arc_list*) nogil
    bint alist_is_done(graph_arc*, arc_list*) nogil
    bint alist_is_empty(arc_list*) nogil
    void alist_combine_top(arc_list*, arc_list*) nogil
    void alist_combine_bottom(arc_list*, arc_list*) nogil
    void alist_reset(arc_list*) nogil
    void alist_push(graph_arc*, arc_list*) nogil
    graph_arc *alist_pop(arc_list*) nogil
    graph_arc *alist_first(arc_list*) nogil
    size_t alist_length(arc_list*) nogil

from .utils cimport MBlockAllocator

cdef class VertexManager:
    cdef size_t v_size
    cdef vertex_list vertices
    cdef MBlockAllocator allocator
    cdef graph_vertex* request(self) except NULL
    cdef void release(self, graph_vertex *v)

cdef class EdgeManager:
    cdef size_t e_size
    cdef arc_list arcs
    cdef MBlockAllocator allocator
    cdef graph_arc* request(self) except NULL
    cdef void release(self, graph_arc *a)
