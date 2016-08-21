
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
# distutils: depends=graph.h, ds_nblist.h
# distutils: include_dirs=lib/include

cimport cython

from .graph cimport Graph
from .core cimport *
from .utils cimport MBlockAllocator

cdef struct hc_marker:
    hc_marker    *next
    graph_vertex *v
    graph_arc    *m_created
    graph_arc    *m_detached
    graph_arc    *g_detached

cdef inline void copy_marker(hc_marker *d, hc_marker *s) nogil:
    d.v = s.v
    d.m_detached = s.m_detached
    d.m_created  = s.m_created
    d.g_detached = s.g_detached

cdef inline hc_marker *push_marker(hc_marker *s, hc_marker **f_markers) nogil:
    cdef hc_marker *d = f_markers[0]
    f_markers[0] = d.next
    d.next = s
    copy_marker(d, s)
    return d

cdef inline void push_v(hc_marker *h, graph_vertex *v) nogil:
    v_detach(v)
    v_attach(v, v_after(h.v))
    h.v = v

cdef inline void push_a(hc_marker *h, graph_arc *a) nogil:
    a_detach(a)
    h.g_detached = a_set_next(a, h.g_detached)

cdef inline void push_e(hc_marker *h, graph_arc *a) nogil:
    push_a(h, a)
    push_a(h, a_cross(a))

cdef inline void push_m(hc_marker *h, graph_arc *a) nogil:
    a_detach(a)
    h.m_detached = a_set_next(a, h.m_detached)

cdef inline graph_arc *second_arc(graph_vertex *v) nogil:
    return a_next(v_arcs_first(v))

cdef inline bint no_second_arc(graph_vertex *v) nogil:
    return v_arcs_is_done(second_arc(v),v)

cdef inline void move_v(vertex_list *k, graph_vertex *v) nogil:
    v_detach(v)
    v_attach(v, vlist_bottom(k))

cdef inline hc_marker *rewind(
    vertex_list *g,
    hc_marker *h,
    graph_arc **f_edges,
    hc_marker **f_markers
) nogil:
    cdef:
        (graph_arc *) a, na
        hc_marker *n = h.next

    h.next = f_markers[0]
    f_markers[0] = h

    # restore vertices to g
    if n.v != h.v:
        vlist_append_chunk_top(g, v_next(n.v), h.v)

    # restore graph minor edge endpoints (to top of arc lists)
    # must be done before removing the minor edges at this level
    a = h.m_detached
    while a != n.m_detached:
        na = a_next(a)
        a_attach(a, v_arcs_top(a_cross(a).target))
        a = na

    # remove graph minor edges created during path contraction
    a = h.m_created
    while a != n.m_created:
        a_detach(a)
        a_detach(a_cross(a))
        f_edges[0] = a_set_next(a, f_edges[0])
        a = a.w0.arcs

    # restore arcs (to the bottom of arc lists)
    a = h.g_detached
    while a != n.g_detached:
        na = a_next(a)
        a_attach(a, v_arcs_bottom(a_cross(a).target))
        a = na
    return n

cdef inline graph_arc *find_endpoint(
    vertex_list *g,
    vertex_list *k,
    hc_marker   *h,
    graph_arc   *c,
    graph_arc   *o,
) nogil:
    cdef:
        (graph_vertex *) v, w, ov = o.target
        (graph_arc *)    a1, ac, a, z
    while 1:
        v  = c.target
        a1 = v_arcs_first(v)
        a  = a_next(a1)
        ac = a_cross(c)

        if v_arcs_is_done(a_next(a), v):
            push_v(h, v) # degree 2
            c = a if a1 == ac else a1
            if c.target == ov:
                push_v(h, ov)
                return o
            continue

        if a1.w0.arcs == NULL: return c
        if a1 == ac:           return c

        # force join of two graph minor edges

        push_v(h, v)

        if a1.target == ov:
            push_v(h, ov)
            return o

        if a != ac:
            a_detach(ac)
            a_attach(ac, a_after(a1))

        a = a_next(ac)
        while not v_arcs_is_done(a, v):
            push_a(h, a_cross(a))
            w = a.target
            z = second_arc(w)
            if v_arcs_is_done(z, w):          return NULL   # degree 1
            if v_arcs_is_done(a_next(z), w):  move_v(k, w)  # degree 2
            a = a_next(a)
        c = a1

cdef inline int path_contraction(
    graph_arc    *c,
    graph_arc    *o,
    vertex_list  *g,
    vertex_list  *k,
    hc_marker    *h,
    graph_arc   **f_edges
) nogil:
    cdef:
       (graph_vertex *) ot, ct
       (graph_arc *) a
       bint z = False

    while 1:
        # contract path in two directions along arcs c and o
        # until no more contractions possible

        z = False
        a = find_endpoint(g, k, h, c, o)
        if a == NULL: return -1
        if a == o:    return 1
        if a != c:
            c = a
            z = True

        a = find_endpoint(g, k, h, o, c)
        if a == NULL: return -1
        if a == c:    return 1
        if a != o:
            o = a
            z = True

        while z:
            a = find_endpoint(g, k, h, c, o)
            if a == NULL: return -1
            if a == o:    return 1
            if a == c:    break
            c = o
            o = a

        # detach path endpoints from graph

        if c.w0.arcs != NULL:  push_m(h, a_cross(c))
        else:                  push_a(h, a_cross(c))
        if o.w0.arcs != NULL:  push_m(h, a_cross(o))
        else:                  push_a(h, a_cross(o))

        ct = c.target
        ot = o.target
        a  = v_arcs_first(ct)

        # pull new endpoints to top of graph so
        # forcing of vertices onto hc occurs sooner

        # seems to have more of an effect on runtime than pre sorting
        # the vertices before starting search

        v_detach(ct)
        v_detach(ot)
        v_attach(ot, vlist_top(g))
        v_attach(ct, vlist_top(g))

        # find and remove pre-existing edge between ot / ct

        while not v_arcs_is_done(a, ct):
            if a.target == ot:
                # remove pre-existing edge
                push_e(h, a)
                if a_cross(c) != o:
                    #change in degree only when not replacing an edge
                    if no_second_arc(ot): move_v(k, ot)
                    if no_second_arc(ct): move_v(k, ct)
                break
            a = a_next(a)

        # place graph minor edge between c.target and o.target

        a = f_edges[0]
        f_edges[0] = a_next(a)
        a.target = ct
        a_cross(a).target = ot
        a.w0.arcs = h.m_created
        a_cross(a).w0.arcs = h.m_created
        h.m_created = a

        # ensure edge is the first arc in each list

        a_attach(a, v_arcs_top(ot))
        a_attach(a_cross(a), v_arcs_top(ct))


        ct = vlist_first(k)
        if vlist_is_done(ct, k): break     # all possible paths contracted
        c = v_arcs_first(ct)
        o = a_next(c)
        push_v(h, ct)
    return 0

cdef inline bint _prep(vertex_list *g, vertex_list *k) nogil:
    cdef:
        (graph_vertex *) n, max_v ,v = vlist_first(g)
        graph_arc *a
        size_t     c = 0, max_c = 0

    # TODO: enable sorting with an option
    #       otherwise pre-ordered vertex list will not be an option
    ## really slow sort by degree
    #while not vlist_is_empty(g):
    #    v = vlist_first(g)
    #    max_c = 0
    #    max_v = v
    #    while not vlist_is_done(v, g):
    #        c = 0
    #        a = v_arcs_first(v)
    #        while not v_arcs_is_done(a,v):
    #            c += 1
    #            a = a_next(a)
    #        if c > max_c:
    #            max_c = c
    #            max_v = v
    #        v = v_next(v)
    #    v_detach(max_v)
    #    v_attach(max_v, vlist_bottom(k))
    #vlist_combine_bottom(g, k)

    v = vlist_first(g)
    while not vlist_is_done(v, g):
        a = v_arcs_first(v)
        c = 0
        while not v_arcs_is_done(a, v):
            a.w0.arcs = NULL
            c += 1
            a = a_next(a)
        n = v_next(v)
        if c == 2: move_v(k, v)
        elif c == 1: return True
        v = n
    return False

cdef void _allocate(
    MBlockAllocator m,
    EdgeManager em,
    size_t count,
    hc_marker **f_markers,
    graph_arc **f_edges
) except *:
    cdef:
        hc_marker *h
        graph_arc *a
    for _ in xrange(count):
        h = <hc_marker*>m.request(sizeof(hc_marker))
        h.next = f_markers[0]
        f_markers[0] = h
        a  = em.request()
        f_edges[0] = a_set_next(a, f_edges[0])

cdef void _deallocate(EdgeManager em, graph_arc *f_edges):
    cdef graph_arc *a
    while f_edges != NULL:
        a = a_next(f_edges)
        em.release(f_edges)
        f_edges = a

@cython.embedsignature(True)
cpdef size_t hc_count(Graph graph) except *:
    if graph is None: return 0  # guard against segfaults...
    cdef:
        graph_arc        dummy_arc
        vertex_list      d2_vertices, hamcycle
        (vertex_list *)  g = &graph.vertices, k = &d2_vertices
        (graph_arc *)    a, a1, a2
        graph_arc       *f_edges = NULL
        hc_marker        base, stop
        (hc_marker *)    h = &base, f_markers = NULL
        MBlockAllocator  m
        (graph_vertex *) v
        size_t           count = 0
        int              x     = 0

    count = vlist_length(g)
    if count < 3 or not graph.connected(): return 0
    m = MBlockAllocator(graph.vb_count()*sizeof(hc_marker))

    _allocate(m, graph.e_manager, count - 1 , &f_markers, &f_edges)

    vlist_reset(k)
    vlist_reset(&hamcycle)

    # prep first marker (so rewind can restore graph)
    h.next = NULL
    h.g_detached = &dummy_arc  # first choice for edge contraction
    h.v = <graph_vertex*>&hamcycle
    h.m_detached = NULL
    h.m_created = v_arcs_first(vlist_first(g))

    h = &stop
    h.next = &base
    copy_marker(h, &base)

    if _prep(g, k):
        _deallocate(graph.e_manager, f_edges)
        return 0

    count = 0
    if not vlist_is_empty(k):
        v = vlist_first(k)
        push_v(h, v)
        a = v_arcs_first(v)
        x = path_contraction(a, a_next(a), g, k, h, &f_edges)
        if x:
            vlist_combine_bottom(g, k)
            if x>0 and vlist_is_empty(g): count += 1
            while h != &base: h = rewind(g, h, &f_edges, &f_markers)
            _deallocate(graph.e_manager, f_edges)
            return count
        if not graph.connected():
            while h != &base: h = rewind(g, h, &f_edges, &f_markers)
            _deallocate(graph.e_manager, f_edges)
            return count

    while 1:
        while not x:
            a = v_arcs_first(vlist_first(g))
            if a.w0.arcs != NULL: a = a_next(a)
            h.g_detached.w0.arcs = a
            h = push_marker(h, &f_markers)
            x = path_contraction(a, a_cross(a), g, k, h, &f_edges)
        while x:
            vlist_combine_bottom(g, k)
            if x>0 and vlist_is_empty(g): count += 1
            if h == &stop: break
            x = 0
            h = rewind(g, h, &f_edges, &f_markers)
            a = h.g_detached.w0.arcs
            h.g_detached.w0.arcs = NULL
            push_e(h, a)  # search exhausted for a at this level
            v  = a.target
            a1 = v_arcs_first(v)
            a2 = a_next(a1)
            if v_arcs_is_done(a_next(a2), v):
                push_v(h, v)
                v = a_cross(a).target
                a = a_next(a_next(v_arcs_first(v)))
                if v_arcs_is_done(a, v): move_v(k, v)
                x = path_contraction(a1, a2, g, k, h, &f_edges)
            else:
                v  = a_cross(a).target
                a1 = v_arcs_first(v)
                a2 = a_next(a1)
                if v_arcs_is_done(a_next(a2), v):
                    push_v(h, v)
                    x = path_contraction(a1, a2, g, k, h, &f_edges)
        else: continue
        break

    while h != &base: h = rewind(g, h, &f_edges, &f_markers)
    _deallocate(graph.e_manager, f_edges)
    return count
