import misc

include "globals.pxi"

DEF TRACE_CACHE_SIZE = 65536 # 64*1024
cdef tuple TRACE_SUPPORTED_OPCODES = ()

DEF TRACE_OP_GET_MEMADDR = 1
DEF TRACE_OP_SET_MEMADDR = 2
DEF TRACE_OP_GET_VALUE_FROM_MEMADDR = 3
DEF TRACE_OP_SET_VALUE_TO_MEMADDR = 4


cdef class TraceStep:
    def __init__(self, object trace):
        self.trace = trace
        self.ops = []
    cpdef handleOp(self, unsigned char op, unsigned long arg1):
        if (op == TRACE_OP_GET_MEMADDR):
            return self.temp[0]
        elif (op == TRACE_OP_SET_MEMADDR):
            self.temp[0] = arg1
        else:
            self.main.printMsg("TraceStep::handleOp: unknown op: {0:d}", op)
    cpdef doStep(self):
        for op in self.ops:
            self.handleOp(op, 0)
    ###


cdef class Trace:
    def __init__(self, object main, object cpu):
        self.main, self.cpu = main, cpu
    cpdef reset(self):
        self.traceList = {}
    cpdef unsigned char isInTrace(self, unsigned char opcode, unsigned long eip):
        if (opcode in TRACE_SUPPORTED_OPCODES and eip in self.traceList):
            return True
        return False
    cpdef executeTraceStep(self, unsigned long eip):
        cdef object traceStep
        if (not (eip in self.traceList)):
            self.main.printMsg("Trace::executeTraceStep: eip isn't in traceList")
            return
        traceStep = self.traceList[eip]
        traceStep.doStep()
    cpdef run(self):
        self.reset()
    ###


