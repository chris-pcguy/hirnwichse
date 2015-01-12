
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

cdef class HirnwichseTest:
    def __init__(self):
        pass
    cpdef run(self):
        cdef unsigned int abc = 0xdeadbeef
        abc = <unsigned char>abc
        print("test=={0:#06x}".format(abc))
        #print("test=={0:#06x}".format(<signed short>(<unsigned short>0x8000)))
        ###



