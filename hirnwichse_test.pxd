
from libc.string cimport memcpy

cdef class HirnwichseTest:
    cdef unsigned char cf, pf, af, zf, sf, tf, if_flag, df, of, iopl, \
                        nt, rf, vm, ac, vif, vip, id
    cdef void func1(self)
    cdef void func2(self, unsigned char var1)
    cdef void func3(self)
    cdef void func4(self, unsigned int flags)
    cpdef run(self)



