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

#include <stddef.h>
#include <stdint.h>

#include "ds_nblist.h"

/* *** undirected graph ***

Vertices in an undirected graph are stored in a vertex_list.

Edges are composed of a pair of directed arcs.

Each undirected graph vertex structure starts as the top of an adjacency list
of outward pointing arcs.

i.e. a vertex can be cast to an arc_list
     or an arc_list can be cast back to a vertex

Edges must be byte aligned to the size of the edge, so that the
opposite facing arc can be quickly found with a xor operation.

This code will not work on systems that do not have pointers that
can be cast as uintptr_t.

Each arc has a utility variable w0 to store an arbitrary word sized
value/object.  (mostly to provide padding)

Each vertex has two utility variables w0, w1.

*/

struct graph_vertex;
struct graph_arc;

LIST_ENTRY_TYPE(graph_arc);
LIST_ENTRY_TYPE(graph_vertex);

typedef LIST_ENTRY_TYPE(graph_vertex) vertex_list;
typedef LIST_ENTRY_TYPE(graph_arc) arc_list;

union word_aux {
    struct graph_vertex *vertex;
    struct graph_arc    *arcs;
    struct graph_arc   **ap;
    vertex_list         *vlist;
    arc_list            *alist;
    void  *other;
    size_t order;
    size_t lowpt;
    long   color;
};

LIST_ENTRY_TYPE(graph_arc) {
    LIST_ENTRY_MEMBERS(graph_arc);
};

struct graph_arc {
    LIST_ENTRY_TYPE(graph_arc) p;     /* list connectivity */
    struct graph_vertex *target;
    union  word_aux  w0;
};

struct graph_edge {
    struct graph_arc a[2];
};

/* access the other arc in an edge

   NOTE: ensure that arc structure size is a power of 2
   NOTE: graph_edge must be memory aligned to 2*sizeof(struct graph_arc) */

inline struct graph_arc* a_cross(struct graph_arc *a)
{
  uintptr_t xa = (uintptr_t)a ^ (uintptr_t)sizeof(struct graph_arc);
  return (struct graph_arc*)xa;
}

LIST_ENTRY_TYPE(graph_vertex) {
    LIST_ENTRY_TYPE(graph_arc) arcs;
    LIST_ENTRY_MEMBERS(graph_vertex);
};

struct graph_vertex {
    LIST_ENTRY_TYPE(graph_vertex) p;
    size_t vid;
    union word_aux w0;
    union word_aux w1;
};



#define ALIST(V) (arc_list*)(V)

#define IE inline

LIST_ENTRY_TYPE_BOILERPLATE(IE,a,graph_arc);
LIST_TYPE_BOILERPLATE(IE,alist,a,arc_list,graph_arc);
LIST_TYPE_EXTRAS_BOILERPLATE(IE,alist,a,arc_list,graph_arc);
LIST_TYPE_BOILERPLATE(IE,v_arcs,a,struct graph_vertex,graph_arc);

LIST_ENTRY_TYPE_BOILERPLATE(IE,v,graph_vertex);
LIST_TYPE_BOILERPLATE(IE,vlist,v,vertex_list,graph_vertex);
LIST_TYPE_EXTRAS_BOILERPLATE(IE,vlist,v,vertex_list,graph_vertex);

typedef struct graph_vertex *(*f_find_vertex)(void *, size_t);
typedef struct graph_vertex *(*f_request_vertex)(void *);
typedef struct graph_arc *(*f_request_edge)(void *);
typedef void (*f_release_vertex)(void *, struct graph_vertex*);
typedef void (*f_release_edge)(void *, struct graph_arc*);
typedef void (*f_register_vertex)(void*, struct graph_vertex*);


struct graph_resources {
    void             *v_manager;
    void             *e_manager;
    void             *v_container;
    vertex_list      *g;
    f_release_edge    release_edge;
    f_request_edge    request_edge;
    f_request_vertex  request_vertex;
    f_release_vertex  release_vertex;
    f_find_vertex     find_vertex;
    f_register_vertex register_vertex;
};

struct graph_vertex *create_vertex(struct graph_resources*, size_t);
struct graph_arc    *create_edge(struct graph_resources*,
                                 struct graph_vertex*, struct graph_vertex*);
struct graph_vertex *ensure_vertex(struct graph_resources*, size_t);
struct graph_arc    *ensure_edge(struct graph_resources*, size_t, size_t);
struct graph_arc    *ensure_edge_v(struct graph_resources *,
                                   struct graph_vertex*, size_t);

void copy_graph(struct graph_resources*, vertex_list*);
void reset_graph_resources(struct graph_resources*);
