#cimport numpy

cdef class Gdt:
    #def __init__(self)
    cpdef loadGdt(self, long gdtBaseAddr)

cdef class Segments:
    cpdef public object main, cpu, registers, gdt
    #def __init__(self, main, cpu, registers)
    cpdef getBase(self, int segId) # segId == segments regId
    cpdef getRealAddr(self, int segId, long offsetAddr)
    cpdef getSegSize(self, int segId) # segId == segments regId
    cpdef getOpSegSize(self, int segId) # segId == segments regId
    cpdef getAddrSegSize(self, int segId) # segId == segments regId

cdef class Registers:
    #cdef object main
    #cdef object cpu
    #cdef object segments
    cpdef public object main, cpu, segments
    ##cpdef numpy.ndarray regs
    cpdef regs
    cpdef public lockPrefix, branchPrefix, repPrefix, segmentOverridePrefix, operandSizePrefix, addressSizePrefix
    #def __init__(self, object main, object cpu)
    cpdef reset(self)
    cpdef resetPrefixes(self)
    cpdef regGetSize(self, regId) # return size in bits
    cpdef regRead(self, long regId, int signed=?, int regIdIsVal=?) # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' here, IT WON'T WORK!!!!
    cpdef regWrite(self, long regId, long value, int signed=?) # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' here, IT WON'T WORK!!!!
    cpdef regReadEip(self, int signed=?)
    cpdef regWriteEip(self, long value)
    cpdef regAdd(self, int regId, long value, int signed=?)
    cpdef regSub(self, int regId, long value, int signed=?)
    cpdef regXor(self, int regId, long value, int signed=?)
    cpdef regAnd(self, int regId, long value, int signed=?)
    cpdef regOr (self, int regId, long value, int signed=?)
    cpdef regSetFlag(self, int regId, long value, int signed=?)
    cpdef regNeg(self, int regId, int signed=?)
    cpdef regNot(self, int regId, int signed=?)
    cpdef regDelFlag(self, int regId, long value, int signed=?) # by val, not bit
    cpdef regDeleteBit(self, int regId, int bit, int signed=?)
    cpdef regSetBit(self, int regId, int bit, int signed=?)
    cpdef regInc(self, int regId, int signed=?)
    cpdef regDec(self, int regId, int signed=?)
    cpdef setEFLAG(self, long flags, int flagState)
    cpdef getFlag(self, int regId, long flags)
    cpdef clearFlags(self, long flags)
    cpdef setFlags(self, long flags)
    cpdef modR_RMLoad(self, tuple rmOperands, int regSize, int signed=?) # imm == unsigned ; disp == signed; regSize in bits
    cpdef modRM_RLoad(self, tuple rmOperands, int regSize) # imm == unsigned ; disp == signed
    cpdef modR_RMSave(self, tuple rmOperands, int regSize, long value) # imm == unsigned ; disp == signed
    cpdef modRM_RSave(self, tuple rmOperands, int regSize, long value, int signed=?) # imm == unsigned ; disp == signed
    cpdef getRegValueWithFlags(self, long modRMflags, int reg)
    cpdef modRMOperands(self, int regSize, long modRMflags=?) # imm == unsigned ; disp == signed ; regSize in bits
    cpdef setFullFlags(self, long reg0, long reg1, int regSize, int method, int signedAsUnsigned=?) # regSize in bits


