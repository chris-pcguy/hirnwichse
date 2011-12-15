

cdef class PythonBios:
    cpdef public object main
    cdef interrupt(self, unsigned char intNum)
    cdef setRetError(self, unsigned char newCF, unsigned short ax)
    cdef run(self)


