
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


cdef bint add_vid_to_list(void *list_, graph_vertex* v) except *:
    (<list>list_).append(v.vid)
    return False

cdef bint add_vid_to_list_exc(void *list_, graph_vertex* v):
    cdef list_wrapper l
    cdef int rv = 0
    try:
        rv = add_vid_to_list(list_, v)
    except:
        import sys
        l = <list_wrapper>list_
        l.lw_exc = sys.exc_info()
        return True
    return rv

cdef class list_wrapper(list):
    cdef object lw_exc

# graph component algorithms, c version w/ callbacks and cython version
# The c version seems to run faster (very slight) when there are few
# components, but the cython version becomes faster with larger
# numbers of components.

cpdef list components_c(Graph g):
    cdef list_wrapper cp = list_wrapper()
    graph_components(
        g.vertices,
        <f_report_vertex>add_vid_to_list_exc,
        <void*>cp)
    if cp.lw_exc is not None:
        raise cp.lw_exc[0], cp.lw_exc[1], cp.lw_exc[2]
    return cp

cpdef list components(Graph g):
    cdef graph_vertex *v = g.vertices
    cdef graph_arc    *a
    cdef size_t order = 0
    cdef list components = []

    if v==NULL:
        return components

    # initialize order etc...

    while (v!=NULL):
        v.w0.order = 0
        v = v.next

    v = g.vertices
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
                a = a_cross(a).next
                continue

        v = v.next

    return components

cpdef bint connected(Graph g):
    # modified form of list components to determine if graph is
    # connected within a single component
    cdef graph_vertex *v = g.vertices
    cdef graph_arc    *a
    cdef size_t count = 0

    if v==NULL:
        return True

    # initialize order etc...

    while v != NULL:
        v.w0.order = 0
        count += 1
        v = v.next

    if count == 1:
        return True

    v = g.vertices

    if v.arcs==NULL:
        return False

    # start dfs on v
    a = v.arcs
    v.w0.order = 1
    count -= 1
    v.w1.arcs = NULL

    while 1:
        if a!=NULL:
            if as_vertex(a).w0.order != 0:
                # skip already visited vertices
                a = a.next
                continue
            # descend into v
            v = as_vertex(a)
            v.w0.order = 1
            count -= 1
            if count == 0:
                return True
            v.w1.arcs = a_cross(a)
            a = v.arcs
            continue
        else:
            # backup to previous vertex
            a = v.w1.arcs
            if a == NULL:
                break
            v = as_vertex(a)
            a = a_cross(a).next
            continue

    return count == 0
