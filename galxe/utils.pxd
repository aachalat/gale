
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


cdef class _MBlock:
    cdef:
        (void*) start, end, ptr, _ptr
        _MBlock  next

        size_t size(self)
        size_t remaining(self)
        bint   in_block(self, void *ptr)
        void  *request(self, size_t bytes) except NULL

cdef class _MBlockIter:
    cdef _MBlock current

cdef class MBlockAllocator:
    cdef:
        _MBlock head
        size_t  block_size
        size_t  align

        void    *request(self, size_t bytes) except NULL
        size_t   available(self, size_t bytes=*)



cdef class TextFileTokenizer:
    cdef object lines, tokens
