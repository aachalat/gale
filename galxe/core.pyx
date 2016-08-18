
#  Copyright 2016 Andrew Chalaturnyk
#
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.



cdef class VertexManager:

    def __cinit__(self, size_t count, size_t size=0):
        vlist_reset(&self.vertices)
        if size < sizeof(graph_vertex): size = sizeof(graph_vertex)
        self.v_size = size
        self.allocator = MBlockAllocator(block_size=count*size)

    cdef graph_vertex* request(self) except NULL:
        cdef graph_vertex *v = vlist_first(&self.vertices)
        if vlist_is_done(v, &self.vertices):
            v = <graph_vertex*>self.allocator.request(self.v_size)
        else:
            v_detach(v)
        return v

    cdef void release(self, graph_vertex* v):
        vlist_push(v, &self.vertices)

    def __str__(self):
        cdef str s
        s =  "vertex allocator:\n"
        s +=  "\tvertices available: %i\n" % (len(self) +
                            self.allocator.available(self.v_size))
        s += "\tblocks allocated: %i\n" % len(self.allocator)
        s += "\tblock size: %i bytes  (%i vertices per block)\n" % (
                            self.allocator.block_size,
                            self.allocator.block_size / self.v_size)
        return s

    def __len__(self):
        return vlist_length(&self.vertices)


cdef class EdgeManager:
    def __cinit__(self, size_t count, size_t size=0):
        alist_reset(&self.arcs)
        if size < sizeof(graph_edge): size = sizeof(graph_edge)
        #power of 2 check on size....)
        assert not (size & (size-1)) , "edge size is not power of 2"
        self.e_size = size
        self.allocator = MBlockAllocator(
                            block_size=count*size, align=size)

    cdef graph_arc* request(self) except NULL:
        cdef graph_arc *a = alist_first(&self.arcs)
        if alist_is_done(a,&self.arcs):
            a = <graph_arc*>self.allocator.request(self.e_size)
        else:
            a_detach(a)
        return a

    cdef void release(self, graph_arc *a):
        cdef graph_arc *t=a_cross(a)
        if t < a:
            a = t
        alist_push(a, &self.arcs)

    def __str__(self):
        cdef str s
        s =  "edge allocator:\n"
        s +=  "\tedges available: %i\n" % (len(self) +
                            self.allocator.available(self.e_size))
        s += "\tblocks allocated: %i\n" % len(self.allocator)
        s += "\tblock size: %i bytes  (%i edges per block)\n" % (
                            self.allocator.block_size,
                            self.allocator.block_size / self.e_size)
        return s

    def __len__(self):
        return alist_length(&self.arcs)

