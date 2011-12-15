
cdef class TraceStep:
    cdef Trace trace
    cdef list ops
    cdef unsigned long temp[4]
    cdef handleOp(self, unsigned char op, unsigned long arg1)
    cdef doStep(self)
    ###

cdef class Trace:
    cpdef public object main
    cdef dict traceList
    cdef reset(self)
    cdef unsigned char isInTrace(self, unsigned char opcode, unsigned long eip)
    cdef executeTraceStep(self, unsigned long eip)
    cdef run(self)
    ###


