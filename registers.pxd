

from mm cimport Mm, ConfigSpace
from segments cimport Segment, GdtEntry, Gdt, Idt, Segments

cdef class ModRMClass:
    cpdef object main
    cdef Registers registers
    cdef unsigned char rm, reg, mod
    cdef unsigned short rmName0, rmName1, rmNameSegId, regName
    cdef long long rmName2
    cdef resetVars(self, unsigned char modRMByte)
    cdef copyRMVars(self, ModRMClass otherInstance)
    cdef sibOperands(self)
    cdef modRMOperands(self, unsigned char regSize, unsigned char modRMflags)
    cdef modRMOperandsResetEip(self, unsigned char regSize, unsigned char modRMflags)
    cdef unsigned long long getRMValueFull(self, unsigned char rmSize)
    cdef long long modRMLoad(self, unsigned char regSize, unsigned char signed, unsigned char allowOverride)
    cdef unsigned long long modRMSave(self, unsigned char regSize, unsigned long long value, unsigned char allowOverride, unsigned char valueOp) # stdAllowOverride==True, stdValueOp==OPCODE_SAVE
    cdef unsigned short modSegLoad(self)
    cdef unsigned short modSegSave(self, unsigned char regSize, unsigned long long value)
    cdef long long modRLoad(self, unsigned char regSize, unsigned char signed)
    cdef unsigned long long modRSave(self, unsigned char regSize, unsigned long long value, unsigned char valueOp)



cdef class Registers:
    cpdef object main
    cdef Segments segments
    cdef ConfigSpace regs
    cdef public unsigned char repPrefix, segmentOverridePrefix, operandSizePrefix, \
                                addressSizePrefix, cpl, iopl, codeSegSize
    cdef public unsigned short eipSizeRegId
    cdef reset(self)
    cdef resetPrefixes(self)
    cdef unsigned short getRegSize(self, unsigned short regId) # return size in bits
    cdef long long getCurrentOpcode(self, unsigned char numBytes, unsigned char signed)
    cdef long long getCurrentOpcodeAdd(self, unsigned char numBytes, unsigned char signed)
    cdef unsigned char getCurrentOpcodeAddWithAddr(self, unsigned short *retSeg, unsigned long *retAddr)
    cdef unsigned short segRead(self, unsigned short segId)
    cdef unsigned short segWrite(self, unsigned short segId, unsigned short segValue)
    cdef long long regRead(self, unsigned short regId, unsigned char signed)
    cdef unsigned long regWrite(self, unsigned short regId, unsigned long value)
    cdef unsigned long regAdd(self, unsigned short regId, long long value)
    cdef unsigned long regAdc(self, unsigned short regId, unsigned long value)
    cdef unsigned long regSub(self, unsigned short regId, unsigned long value)
    cdef unsigned long regSbb(self, unsigned short regId, unsigned long value)
    cdef unsigned long regXor(self, unsigned short regId, unsigned long value)
    cdef unsigned long regAnd(self, unsigned short regId, unsigned long value)
    cdef unsigned long regOr (self, unsigned short regId, unsigned long value)
    cdef unsigned long regNeg(self, unsigned short regId)
    cdef unsigned long regNot(self, unsigned short regId)
    cdef unsigned long regWriteWithOp(self, unsigned short regId, unsigned long value, unsigned char valueOp)
    cdef unsigned long valSetBit(self, unsigned long value, unsigned char bit, unsigned char state)
    cdef unsigned char valGetBit(self, unsigned long value, unsigned char bit) # return True if bit is set, otherwise False
    cdef unsigned long getEFLAG(self, unsigned long flags)
    cdef unsigned long setEFLAG(self, unsigned long flags, unsigned char flagState)
    cdef unsigned long getFlag(self, unsigned short regId, unsigned long flags)
    cdef unsigned short getWordAsDword(self, unsigned short regWord, unsigned char wantRegSize)
    cdef setSZP(self, unsigned long value, unsigned char regSize)
    cdef setSZP_O0(self, unsigned long value, unsigned char regSize)
    cdef setSZP_C0_O0_A0(self, unsigned long value, unsigned char regSize)
    cdef unsigned short getRegNameWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize)
    cdef unsigned char getCond(self, unsigned char index)
    cdef setFullFlags(self, long long reg0, long long reg1, unsigned char regSize, unsigned char method, unsigned char signed)
    #cdef checkMemAccessRights(self, unsigned short segId, unsigned char write)
    cdef unsigned long getRealAddr(self, unsigned short segId, long long offsetAddr)
    cdef unsigned long mmGetRealAddr(self, long long mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef bytes mmRead(self, long long mmAddr, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride)
    cdef long long mmReadValueSigned(self, long long mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long long mmReadValueUnsigned(self, long long mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef mmWrite(self, long long mmAddr, bytes data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long long mmWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long long mmWriteValueWithOp(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride, unsigned char valueOp)
    cdef unsigned char getSegSize(self, unsigned short segId)
    cdef unsigned char isSegPresent(self, unsigned short segId)
    cdef unsigned char getOpSegSize(self, unsigned short segId)
    cdef unsigned char getAddrSegSize(self, unsigned short segId)
    cdef unsigned char getOpCodeSegSize(self)
    cdef unsigned char getAddrCodeSegSize(self)
    cdef getOpAddrSegSize(self, unsigned short segId, unsigned char *opSize, unsigned char *addrSize)
    cdef getOpAddrCodeSegSize(self, unsigned char *opSize, unsigned char *addrSize)
    cdef run(self)


