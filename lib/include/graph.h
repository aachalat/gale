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

struct graph_arc {
    struct graph_arc **target;  /* target vertex arc list,
                                   also can cast to graph_vertex* */
    struct graph_arc *next;
};

struct graph_edge_lhs {
    struct graph_arc a;
    struct graph_arc pad;
};

struct graph_edge_rhs {
    struct graph_arc pad;
    struct graph_arc a;
};

union graph_edge {
    struct graph_edge_lhs l;
    struct graph_edge_rhs r;
    struct graph_arc a[2];
};

/* TODO: allow for different pointer sizes, will require some work
   TODO: ensure that arc structure size is a power of 2
   NOTE: graph_edge must be memory aligned to 2*sizeof(struct graph_arc) */

#define a_cross(ARC) \
((struct graph_arc*)(((uintptr_t)(ARC)) \
    ^ (uintptr_t)(sizeof(struct graph_arc))))

struct graph_vertex;

union word_aux {
    struct graph_vertex *vertex;
    struct graph_arc    *arcs;
    void  *other;
    size_t order;
    size_t lowpt;
    size_t color;
};

struct graph_vertex {
    struct graph_arc    *arcs;    /* keep at top of struct !!! */
    struct graph_vertex *next;
    size_t vid;
    union word_aux w0;
    union word_aux w1;
};

#define as_vertex(ARC) \
    ((struct graph_vertex*)((struct graph_arc*)(ARC)->target))

typedef struct graph_vertex *(*f_request_vertex)(void *);
typedef struct graph_arc *(*f_request_edge)(void *);
typedef void (*f_release_vertex)(void *, struct graph_vertex*);
typedef void (*f_release_edge)(void *, struct graph_arc*);

struct graph_resources {
    void            *v_manager;
    void            *e_manager;
    f_release_edge    release_edge;
    f_request_edge    request_edge;
    f_request_vertex request_vertex;
    f_release_vertex release_vertex;
};

struct graph_vertex *find_vertex(struct graph_vertex*, size_t);
struct graph_vertex *create_vertex(struct graph_resources*, size_t);
struct graph_arc    *find_edge_by_vid(struct graph_vertex*, size_t, size_t);
struct graph_arc    *find_edge(struct graph_vertex*, struct graph_vertex*);
struct graph_arc    *create_edge(struct graph_resources*, struct graph_vertex*, struct graph_vertex*);
struct graph_vertex *ensure_vertex(struct graph_resources *,struct graph_vertex **, size_t);
struct graph_arc *ensure_edge(struct graph_resources *, struct graph_vertex **, size_t, size_t);

void copy_graph(struct graph_resources*, struct graph_vertex*, struct graph_vertex**);
