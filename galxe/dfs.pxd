
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
from .graph cimport Graph  # cyclic import TODO: try to remove this

cdef extern from "graph_dfs.h":
    ctypedef bint (*f_report_vertex)(void*, graph_vertex*)
    size_t graph_components(vertex_list*,f_report_vertex,void*) except *
    bint graph_connected(vertex_list*)

cpdef Graph components(Graph)

