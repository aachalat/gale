
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
    struct graph_arc:
        graph_arc **target
        graph_arc *next

    struct graph_vertex

    union word_aux:
        graph_vertex *vertex
        graph_arc    *arcs
        void         *other
        size_t        order
        size_t        lowpt
        size_t        color

    struct graph_vertex:
        graph_arc    *arcs
        graph_vertex *next
        size_t vid
        word_aux    w0
        word_aux    w1

    union graph_edge:
        graph_arc a[2]

    ctypedef graph_vertex *(*f_request_vertex)(void *)
    ctypedef graph_arc *(*f_request_edge)(void *)
    ctypedef void (*f_release_vertex)(void *, graph_vertex*)
    ctypedef void (*f_release_edge)(void *, graph_arc*)

    struct graph_resources:
        void            *v_manager;
        void            *e_manager;
        f_release_edge   release_edge;
        f_request_edge   request_edge;
        f_request_vertex request_vertex;
        f_release_vertex release_vertex;

    graph_vertex *as_vertex(graph_arc *a)
    graph_arc    *a_cross(graph_arc *a)

    graph_vertex *find_vertex(graph_vertex*, size_t)
    graph_vertex *ensure_vertex(graph_resources*,graph_vertex **, size_t) except NULL
    graph_arc    *ensure_edge(graph_resources*,graph_vertex **, size_t, size_t) except NULL

    void copy_graph(graph_resources*, graph_vertex*, graph_vertex**) except *

from .utils cimport MBlockAllocator


cdef class VertexManager:
    cdef size_t v_size
    cdef graph_vertex *vertices
    cdef MBlockAllocator allocator
    cdef graph_vertex* request(self) except NULL
    cdef void release(self, graph_vertex *v)

#cdef class _ArcManager:
#    cdef size_t a_size
#    cdef graph_arc *arcs
#    cdef MBlockAllocator allocator
#    cdef graph_arc* request(self) except NULL
#    cdef void release(self, graph_arc *a)

cdef class EdgeManager:
    cdef size_t e_size
    cdef graph_arc *arcs
    cdef MBlockAllocator allocator
    cdef graph_arc* request(self) except NULL
    cdef void release(self, graph_arc *a)

cdef void set_graph_resources(graph_resources *r, VertexManager, EdgeManager)
