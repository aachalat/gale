
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
        self.vertices = NULL
        if size < sizeof(graph_vertex): size = sizeof(graph_vertex)
        self.v_size = size
        self.allocator = MBlockAllocator(block_size=count*size)

    cdef graph_vertex* request(self) except NULL:
        cdef graph_vertex *v = self.vertices
        if v == NULL:
            v = <graph_vertex*>self.allocator.request(self.v_size)
        else:
            self.vertices = v.next
        return v

    cdef void release(self, graph_vertex* v):
        v.next = self.vertices
        self.vertices = v.next
        
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
        cdef graph_vertex *v = self.vertices
        cdef int x = 0
        while v!=NULL:
            x += 1
            v = v.next
        return x


#cdef class _ArcManager:
#    def __cinit__(self, size_t count, size_t size=0):
#        if size < sizeof(graph_vertex): size = sizeof(graph_arc)
#        self.a_size = size
#        self.arcs = NULL
#        self.allocator = MBlockAllocator(block_size=count*size)
#    cdef graph_arc* request(self) except NULL:
#        cdef graph_arc *a = self.arcs
#        if a == NULL:
#            a = <graph_arc*>self.allocator.request(self.a_size)
#        else:
#            self.arcs = a.next
#        return a
#    cdef void release(self, graph_arc *a):
#        a.next = self.arcs
#        self.arcs = a
#    def __str__(self):
#        cdef str s
#        s =  "arc allocator:\n"
#        s +=  "\tarcs available: %i\n" % (len(self) + 
#                            self.allocator.available(self.a_size)) 
#        s += "\tblocks allocated: %i\n" % len(self.allocator)
#        s += "\tblock size: %i bytes  (%i arcs per block)\n" % (
#                            self.allocator.block_size, 
#                            self.allocator.block_size / self.a_size)
#        return s
#    def __len__(self):
#        cdef graph_arc *a = self.arcs
#        cdef int x = 0
#        while (a!=NULL):
#            x += 1
#            a = a.next
#        return x

cdef class EdgeManager:
    def __cinit__(self, size_t count, size_t size=0):
        if size < sizeof(graph_vertex): size = sizeof(graph_edge)
        #power of 2 check on size....)
        assert (not (size & (size-1)))
        self.e_size = size
        self.arcs = NULL
        self.allocator = MBlockAllocator(block_size=count*size, align=sizeof(graph_edge))
    cdef graph_arc* request(self) except NULL:
        cdef graph_arc *a = self.arcs
        if a == NULL:
            a = <graph_arc*>self.allocator.request(self.e_size)
        else:
            self.arcs = a.next
        return a
    cdef void release(self, graph_arc *a):
        if a_cross(a) < a:
            a = a_cross(a)
        a.next = self.arcs
        self.arcs = a
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
        cdef graph_arc *a = self.arcs
        cdef int x = 0
        while (a!=NULL):
            x += 1
            a = a.next
        return x