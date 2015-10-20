
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

import struct

cdef class HirnwichseTest:
    def __init__(self):
        pass
    cdef void func1(self):
        cdef unsigned long int a1, a2
        cdef double b1, b2
        a1 = 0x4150017ec0000000
        a2 = 0x4147ffff80000000
        b1 = (<double*>&a1)[0]
        b2 = (<double*>&a2)[0]
        print("test3_a1=={0:f}".format(b1))
        print("test3_a2=={0:f}".format(b2))
        print("test3_c1=={0:s}".format(repr(struct.pack(">d", b1/b2))))
    cpdef run(self):
        print("test1")
        self.func1()
        print("test2")



