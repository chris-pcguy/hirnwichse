

cdef class PythonBios:
    cpdef object main
    cpdef unsigned char interrupt(self, unsigned char intNum)
    cdef setRetError(self, unsigned char newCF, unsigned short ax)
    cdef run(self)


