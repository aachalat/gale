/*

  Copyright 2016 Andrew Chalaturnyk


  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  
      http://www.apache.org/licenses/LICENSE-2.0


  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

#pragma once

#include "graph.h"

struct hamcycle_vertex {
    struct graph_vertex vertex;
    struct graph_vertex *endpoint;  /* other end of segment, otherwise NULL if not part of one */
    struct graph_arc *removed_arcs; /* removed edges/arcs at this point of the search tree */
};

