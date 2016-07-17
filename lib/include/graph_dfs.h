
#pragma once

#include "graph.h"

/* various dfs graph algorithms  */
typedef int (*f_report_vertex)(void *, struct graph_vertex*);

size_t graph_components(struct graph_vertex*, f_report_vertex, void*);
