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

#include "graph_dfs.h"

size_t
graph_components(vertex_list *g, f_report_vertex found, void *container)
{
    struct graph_arc *a;
    struct graph_vertex *v = vlist_first(g);
    size_t order=0, count=0;

    if (vlist_is_done(v, g)) return count;

    v = vlist_first(g);
    while (!vlist_is_done(v, g)) {
        v->w0.order = 0;
        v = v_next(v);
    }

    v = vlist_first(g);
    while (!vlist_is_done(v, g)) {
        a = v_arcs_first(v);
        if (v_arcs_is_done(a, v)) {
            count++;
            if (found && found(container, v)) return count;
            v = v_next(v);
            continue;
        }

        if (v->w0.order) {
            v = v_next(v);
            continue;
        }

        v->w0.order = ++order;
        count++;
        if (found && found(container, v)) return count;
        v->w1.arcs  = NULL;

        while (1){
            if (!v_arcs_is_done(a, v)) {
                if (a->target->w0.order) {
                    a = a_next(a);
                    continue;
                }
                v = a->target;
                v->w0.order = ++order;
                v->w1.arcs = a_cross(a);
                a = v_arcs_first(v);
                continue;

            } else {
                if (!(a = v->w1.arcs)) break;
                v = a->target;
                a = a_next(a_cross(a));
                continue;
            }
        }
        v = v_next(v);
    }

    return count;

}

int
graph_connected(vertex_list *g)
{
    struct graph_arc *a;
    struct graph_vertex *v = vlist_first(g);

    size_t count = 0;

    if (vlist_is_done(v, g)) return (1==1);

    do {
        v->w0.order = 0;
        count++;
        v = v_next(v);
    } while (!vlist_is_done(v, g));

    if (count == 1) return (1==1);

    v = vlist_first(g);
    a = v_arcs_first(v);
    if (v_arcs_is_done(a, v)) return (0==1);

    v->w0.order = 1;
    count--;

    v->w1.arcs = NULL;
    while (1){
        if (!v_arcs_is_done(a, v)) {
            if (a->target->w0.order) {
                a = a_next(a);
                continue;
            }
            v = a->target;
            v->w0.order = 1;
            count--;
            v->w1.arcs = a_cross(a);
            a = v_arcs_first(v);
            continue;

        } else {
            if (!(a = v->w1.arcs)) break;
            v = a->target;
            a = a_next(a_cross(a));
            continue;
        }
    }
    return (count == 0);
}
