
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

from cpython.mem cimport PyMem_Malloc, PyMem_Free
from libc.stdint cimport uintptr_t

cdef class _MBlock:
    def __cinit__(self, size_t size, size_t align=0):
        cdef void* ptr 
        cdef size_t rsize=size
        cdef uintptr_t z
        if (align and not (align & (align-1))):
            rsize += align - 1
        self._ptr = ptr = <void*>PyMem_Malloc(rsize) 
        if ptr == NULL:
            raise MemoryError()
        if (align and not (align & (align-1))):
            z = align - 1
            ptr=<void*>(((<uintptr_t>ptr) + z) & ~z) 
            #if ptr != self._ptr:
            #    print "moved ptr:"
            #    print '\tnew:\t\t',<uintptr_t>ptr
            #    print '\tassigned:\t',<uintptr_t>self._ptr
            #    print '\tdistance:\t',<uintptr_t>ptr - <uintptr_t>self._ptr
            #    print '\talignment:\t',align
        self.start = ptr
        self.end = <void*>((<char*>self.start)+size)
        self.ptr = self.end
        self.next = None

    def __dealloc__(self):
        PyMem_Free(self._ptr)

    def __len__(self):
        return self.size()

    cdef size_t size(self):
        return <char*>self.end - <char*>self._ptr

    cdef size_t remaining(self):
        return <char*>self.ptr - <char*>self.start

    cdef bint in_block(self, void *ptr):
        return (<char*>ptr >= <char*>self.start and 
                <char*>ptr < <char*>self.end)

    cdef void_ptr request(self, size_t bytes) except NULL:
        cdef char *ptr = (<char*>self.ptr) - bytes
        if ptr < <char*>self.start:
            raise MemoryError()
        self.ptr = <void*>ptr
        return self.ptr

cdef class _MBlockIter:
    def __cinit__(self, _MBlock m):
        self.current = m
    def __iter__(self):
        return self
    def __next__(self):
        cdef _MBlock m = self.current
        if m is not None:
            self.current = m.next
            return m
        raise StopIteration()


cdef class MBlockAllocator:
    def __cinit__(self, size_t block_size, align=0):
        self.align = align
        self.block_size = block_size
    def __iter__(self):
        return _MBlockIter(self.head)
    def __len__(self):
        return sum(1 for _ in iter(self))
    cdef void_ptr request(self, size_t bytes) except NULL:
        cdef _MBlock mb = self.head
        if bytes > self.block_size:
            raise MemoryError("block_size is lower than requested bytes.")
        if mb is None or mb.remaining() < bytes:
            mb = _MBlock(self.block_size, align=self.align)
            mb.next = self.head
            self.head = mb
        return mb.request(bytes)
    cdef size_t available(self, size_t bytes=1):
        if self.head is None:
            return 0
        return <size_t>(self.head.remaining() / bytes)