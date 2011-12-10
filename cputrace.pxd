
cdef class TraceStep:
    cpdef public object trace
    cdef list ops
    cdef unsigned long temp[4]
    cpdef handleOp(self, unsigned char op, unsigned long arg1)
    cpdef doStep(self)
    ###

cdef class Trace:
    cpdef public object main, cpu
    cdef dict traceList
    cpdef reset(self)
    cpdef unsigned char isInTrace(self, unsigned char opcode, unsigned long eip)
    cpdef executeTraceStep(self, unsigned long eip)
    cpdef run(self)
    ###


