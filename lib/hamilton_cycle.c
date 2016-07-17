

struct hamcycle_vertex {
    struct graph_vertex v;
    struct graph_vertex *other_end;
    struct graph_arc *removed_arcs;
}