
from libc.stdint cimport *
from mm cimport ConfigSpace
from hirnwichse_main cimport Hirnwichse

include "globals.pxi"
include "cpu_globals.pxi"

cdef class HirnwichseTest:
    cdef Hirnwichse main
    cdef ConfigSpace configSpace
    cdef void func1(self) nogil
    cpdef run(self)



