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

inline struct graph_vertex*
find_vertex(struct graph_vertex *v, size_t vid)
{
    while (v && v->vid != vid) v = v->next;
    return v;
}

inline struct graph_arc*
find_edge_by_vid(struct graph_vertex* z, size_t u_vid, size_t v_vid)
{
    struct graph_vertex *v, *u;
    if (!(v=find_vertex(z, v_vid))) return (struct graph_arc*)v;
    if (!(u=find_vertex(z, u_vid))) return (struct graph_arc*)u;
    return find_edge(u, v);
}

inline struct graph_arc*
find_edge(struct graph_vertex* u, struct graph_vertex* v)
{
    struct graph_arc* a = u->arcs;
    while (a && as_vertex(a)!=v) a=a->next;
    return a;
}

inline struct graph_vertex* 
create_vertex(struct graph_resources *r, size_t vid)
{
    struct graph_vertex* v = r->request_vertex(r->v_manager);
    if (!v) return v;
    v->vid = vid;
    v->arcs = (struct graph_arc*)'\0';
    return v;
}

inline struct graph_arc* 
create_edge(
    struct graph_resources *r, 
    struct graph_vertex* u, 
    struct graph_vertex* v)
{
    struct graph_arc *a;

    a = r->request_edge(r->e_manager);
    if (!a) return a;

    a->target = &(v->arcs);
    a->next = u->arcs;
    u->arcs = a;
    a = a_cross(a);
    a->target = &(u->arcs);
    a->next = v->arcs;
    v->arcs = a;

    return a_cross(a);
}

inline struct graph_vertex *
ensure_vertex(
    struct graph_resources *r, 
    struct graph_vertex **g,
    size_t vid)
{
    struct graph_vertex *v=find_vertex(*g, vid);
    if (!v) {
        v = create_vertex(r, vid);
        if (!v) return v;
        v->next = *g;
        *g = v;
    }
    return v;
}

inline struct graph_arc *
ensure_edge(
    struct graph_resources *r, 
    struct graph_vertex **g,
    size_t u_vid,
    size_t v_vid)
{
    struct graph_vertex *u, *v;
    struct graph_arc *au;

    u=ensure_vertex(r, g, u_vid);
    if (!u) return (struct graph_arc*)'\0';
    v=ensure_vertex(r, g, v_vid); 
    if (!v) return (struct graph_arc*)'\0';
    au = find_edge(u, v); 
    if (!au) au = create_edge(r, u, v);
    return au;
}

void
copy_graph(
    struct graph_resources *r,
    struct graph_vertex *source,
    struct graph_vertex **dest)
{
    struct graph_vertex *tu, *v=source, *u=*dest;
    struct graph_arc    *a;

    /* initialise v->w0.vertex to copy */ 
    if (u) {
        while (v) {
            tu = find_vertex(u, v->vid);
            if (!tu) tu = create_vertex(r, v->vid);
            if (!tu) return; /* TODO: cleanup already created... */
            tu->next = u;
            u = tu;
            v->w0.vertex = tu;
            v = v->next;
        }
        v = source;
        while (v) {
            a = v->arcs;
            while (a) {
                tu = as_vertex(a);
                if (v->vid < tu->vid 
                    && !find_edge(v->w0.vertex, tu->w0.vertex)
                    && !create_edge(r, v->w0.vertex, 
                                        tu->w0.vertex)) return;
                
                a = a->next;
            }
            v = v->next;
        }
    } else  {
        while (v) {
            tu = create_vertex(r, v->vid);
            if (!tu) return;
            tu->next = u;
            u = tu;
            v->w0.vertex = tu;
            v = v->next;
        }
        v = source;
        while (v) {
            a = v->arcs;
            while (a) {
                tu = as_vertex(a);
                if (v->vid < tu->vid 
                     && !create_edge(r, v->w0.vertex, 
                                        tu->w0.vertex)) return;
                a = a->next;
            }
            v = v->next;
        }
    }
    *dest = u;
}
