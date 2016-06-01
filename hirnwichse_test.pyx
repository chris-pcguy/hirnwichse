
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

cdef class HirnwichseTest:
    def __init__(self):
        pass
    cdef void func1(self) nogil:
        with gil:
            raise NameError()
    cpdef run(self):
        self.func1()



