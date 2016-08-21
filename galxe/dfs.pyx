
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
# distutils: depends=graph_dfs.h, ds_nblist.h
# distutils: include_dirs=lib/include

from .core cimport create_vertex

cdef bint add_to_graph(void *g, graph_vertex* v):
    try:
        create_vertex(&(<graph_wrapper>g).resources, v.vid)
        return False
    except:
        import sys
        (<graph_wrapper>g).w_exc = sys.exc_info()
    return True

# use a graph to hold representive vertices for each component
# seems to be more appropriate than a list of numbers...

# any exceptions that occur in add_to_graph are held in w_exc to
# be re-raised once graph_components returns
cdef class graph_wrapper(Graph):
    cdef object w_exc

cpdef Graph components(Graph g):
    cdef graph_wrapper cp = graph_wrapper(vb_count=g.vb_count(),
                                          fast_lookup=False)
    graph_components(&g.vertices, <f_report_vertex>add_to_graph, <void*>cp)
    if cp.w_exc is not None:
        raise cp.w_exc[0], cp.lw_exc[1], cp.lw_exc[2]
    return type(g)(cp) #return graph with same type as was entered...
