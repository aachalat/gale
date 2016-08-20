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

#include "graph.h"

/* declare extern prototypes to force procedure code to be
   generated for inline functions (for debugging),
   since all inline code seems to actually be inline
   (see gcc manual for more) */

LIST_ENTRY_TYPE_PROTO(extern,a,graph_arc);
LIST_TYPE_PROTO(extern,alist,a,arc_list,graph_arc);
LIST_TYPE_EXTRAS_PROTO(extern,alist,a,arc_list,graph_arc);
LIST_TYPE_PROTO(extern,v_arcs,a,struct graph_vertex,graph_arc);

LIST_ENTRY_TYPE_PROTO(extern,v,graph_vertex);
LIST_TYPE_PROTO(extern,vlist,v,vertex_list,graph_vertex);
LIST_TYPE_EXTRAS_PROTO(extern,vlist,v,vertex_list,graph_vertex);

extern struct graph_arc* a_cross(struct graph_arc *a);

static struct graph_vertex*
find_vertex(vertex_list* g, size_t vid)
{
    struct graph_vertex* v = vlist_first(g);
    for (;;) {
        if (vlist_is_done(v, g)) return NULL;
        if (v->vid == vid) return v;
        v = v_next(v);
    }
    return NULL;
}

static void
register_vertex(void *container, struct graph_vertex *v)
{
    /* do nothing */
    return;
}

void
reset_graph_resources(struct graph_resources *r)
{
    r->v_manager = NULL;
    r->e_manager = NULL;
    r->v_container = NULL;
    r->g = NULL;
    r->release_edge = NULL;
    r->request_edge = NULL;
    r->find_vertex = (f_find_vertex)&find_vertex;
    r->register_vertex = (f_register_vertex)&register_vertex;
    r->request_vertex = NULL;
    r->release_vertex = NULL;
}

static inline struct graph_arc*
find_edge(struct graph_vertex *u, struct graph_vertex *v)
{
    struct graph_arc* a = v_arcs_first(u);
    while (!v_arcs_is_done(a,u)) {
        if (a->target == v) return a;
        a = a_next(a);
    }
    return NULL;
}

struct graph_vertex*
create_vertex(struct graph_resources *r, size_t vid)
{
    struct graph_vertex* v = r->request_vertex(r->v_manager);
    if (!v) return v;
    v->vid = vid;
    v_arcs_reset(v);
    v_attach(v, vlist_bottom(r->g));
    r->register_vertex(r->v_container, v);
    return v;
}

struct graph_arc*
create_edge(
    struct graph_resources *r,
    struct graph_vertex* u,
    struct graph_vertex* v)
{
    struct graph_arc *a = r->request_edge(r->e_manager);
    if (!a) return a;
    a->target = v;
    a_attach(a, v_arcs_top(u));
    a = a_cross(a);
    a->target = u;
    a_attach(a, v_arcs_top(v));
    return a_cross(a);
}

struct graph_vertex *
ensure_vertex(struct graph_resources *r, size_t vid)
{
    struct graph_vertex *v;
    if (!(v = r->find_vertex(r->v_container, vid))) {
        v = create_vertex(r, vid);
    }
    return v;
}

struct graph_arc *
ensure_edge(struct graph_resources *r, size_t u_vid, size_t v_vid)
{
    struct graph_vertex *u, *v;
    struct graph_arc *a=NULL;
    int z=0;

    z=!(u=r->find_vertex(r->v_container, u_vid));
    z=!(v=r->find_vertex(r->v_container, v_vid)) || z;

    if ((!u && !(u=create_vertex(r, u_vid))) ||
        (!v && !(v=create_vertex(r, v_vid)))) return NULL;

    if (z || !(a=find_edge(u, v))) a=create_edge(r, u, v);

    return a;
}

struct graph_arc *
ensure_edge_v(struct graph_resources *r, struct graph_vertex* u, size_t v_vid)
{
    struct graph_vertex *v;
    struct graph_arc *a=NULL;
    int z=0;

    z=!(v=r->find_vertex(r->v_container, v_vid));

    if (!v && !(v=create_vertex(r, v_vid))) return NULL;

    if (z || !(a=find_edge(u, v))) a=create_edge(r, u, v);

    return a;
}

void
copy_graph(struct graph_resources *dest, vertex_list *g)
{
    struct graph_vertex *x, *u, *v;
    struct graph_arc    *a;
    size_t v_vid;

    if (vlist_is_empty(dest->g)) {

        v=vlist_first(g);
        while (!vlist_is_done(v, g)) {
            if (!(v->w0.vertex = create_vertex(dest, v->vid))) return;
            v = v_next(v);
        }

        v = vlist_first(g);
        while (!vlist_is_done(v, g)) {
            a = v_arcs_first(v);
            v_vid = v->vid;
            x = v->w0.vertex;
            while (!v_arcs_is_done(a, v)) {
                u = a->target->w0.vertex;
                a = a_next(a);
                if (v_vid > u->vid) continue;
                if (!create_edge(dest, u, x)) return;
            }
            v = v_next(v);
        }
        return;
    }

    /* slow version, vertices and edges may already exist */

    v=vlist_first(g);
    while (!vlist_is_done(v, g)) {
        if (!(v->w0.vertex = ensure_vertex(dest, v->vid))) return;
        v = v_next(v);
    }

    v = vlist_first(g);
    while (!vlist_is_done(v, g)) {
        a = v_arcs_first(v);
        v_vid = v->vid;
        x = v->w0.vertex;
        while (!v_arcs_is_done(a, v)) {
            u = a->target->w0.vertex;
            a = a_next(a);
            if (v_vid > u->vid) continue;
            if (!find_edge(u, x) && !create_edge(dest, u, x)) return;
        }
        v = v_next(v);
    }
}
