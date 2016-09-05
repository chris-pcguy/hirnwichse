
from libc.stdint cimport *

from hirnwichse_main cimport Hirnwichse

cdef class Misc:
    cdef Hirnwichse main
    cdef object createThread(self, object threadFunc, object classObject)


