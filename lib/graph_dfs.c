
#include "graph_dfs.h"
 
size_t
graph_components(
    struct graph_vertex* vertices, 
    f_report_vertex found_component_rep,
    void *container)
{
    struct graph_arc *a;
    struct graph_vertex *v=vertices;
    size_t order=0, count=0;

    if (!v) return count;

    while (v) { 
        v->w0.order = 0;
        v = v->next;
    }

    v = vertices;

    while (v) {
        if (!v->arcs) {
            count++;
            if (found_component_rep(container, v)) return count;
            v = v->next;
            continue;
        }
        
        if (v->w0.order) {
            v = v->next;
            continue;
        }

        a = v->arcs;
        v->w0.order = ++order;
        count++;
        if (found_component_rep(container, v)) return count;
        v->w1.arcs  = (struct graph_arc*)'\0';

        while (1){
            if (a) {
                if (as_vertex(a)->w0.order) {
                    a = a->next;
                    continue;
                }
                v = as_vertex(a);
                v->w0.order = ++order;
                v->w1.arcs = a_cross(a);
                a = v->arcs;
                continue;

            } else {
                a = v->w1.arcs;
                if (!a) break;
                v = as_vertex(a);
                a = a_cross(a)->next;
                continue;

            }

        }
        v = v->next;
    }

    return count;

}