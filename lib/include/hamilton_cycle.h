
#pragma once

#include "graph.h"

struct hamcycle_vertex {
    struct graph_vertex vertex;
    struct graph_vertex *endpoint;  /* other end of segment, otherwise NULL if not part of one */
    struct graph_arc *removed_arcs; /* removed edges/arcs at this point of the search tree */
};

