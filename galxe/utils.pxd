
ctypedef void* void_ptr  

cdef class _MBlock:
    cdef:
        void_ptr start, end, ptr, _ptr
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


