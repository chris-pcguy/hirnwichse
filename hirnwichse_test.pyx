
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True


cdef class HirnwichseTest:
    def __init__(self):
        pass
    cdef func1(self):
        cdef char *a = b"\xef\xbe\xad\xde"
        cdef unsigned int *b = <unsigned int*>a
        print("test3=={0:#010x}".format(b[0]))
    cpdef run(self):
        print("test1")
        self.func1()
        print("test2")



