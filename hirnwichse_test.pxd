

cdef class HirnwichseTest:
    cpdef object threadObject, eventObject
    cpdef unsigned char timerEnabled
    cpdef object createThread(self, object threadFunc, unsigned char startIt)
    cpdef runThread(self)
    cpdef run(self)



