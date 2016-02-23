
from libc.string cimport memcpy

cdef class HirnwichseTest:
    cdef void func1(self)
    cdef void func2(self, unsigned char var1)
    cdef void func3(self)
    cpdef run(self)



