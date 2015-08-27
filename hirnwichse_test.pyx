
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True


cdef class HirnwichseTest:
    def __init__(self):
        pass
    cdef void func1(self):
        #cdef char *a = b"\xef\xbe\xad\xde"
        #cdef unsigned int *b = <unsigned int*>a
        #print("test3=={0:#010x}".format(b[0]))
        cdef unsigned long int i, j
        for i in range(65535):
            for j in range(10000):
                pass
    cpdef run(self):
        print("test1")
        self.func1()
        print("test2")



