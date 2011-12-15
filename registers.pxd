

from mm cimport Mm, ConfigSpace
from segments cimport Gdt, Idt, Segments

cdef class Registers:
    cpdef public object main
    cdef public Segments segments
    cdef public ConfigSpace regs
    cdef public unsigned char lockPrefix, repPrefix, segmentOverridePrefix, operandSizePrefix, \
                              addressSizePrefix, cpl, iopl, A20Active, protectedModeOn
    cdef reset(self)
    cdef resetPrefixes(self)
    cdef unsigned short getRegSize(self, unsigned short regId) # return size in bits
    cdef unsigned char isInProtectedMode(self)
    cdef unsigned char getA20State(self)
    cdef setA20State(self, unsigned char state)
    cdef unsigned long long getCurrentOpcodeAddr(self)
    cdef long long getCurrentOpcode(self, unsigned char numBytes, unsigned char signed)
    cdef long long getCurrentOpcodeAdd(self, unsigned char numBytes, unsigned char signed)
    cdef tuple getCurrentOpcodeWithAddr(self, unsigned char getAddr, unsigned char numBytes, unsigned char signed)
    cdef tuple getCurrentOpcodeAddWithAddr(self, unsigned char getAddr, unsigned char numBytes, unsigned char signed)
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
    cdef unsigned long long getRMValueFull(self, tuple rmNames, unsigned char rmSize)
    cdef long long modRMLoad(self, tuple rmOperands, unsigned char regSize, unsigned char signed, unsigned char allowOverride) # imm == unsigned ; disp == signed; regSize in bits
    cdef unsigned long long modRMSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value, unsigned char allowOverride, unsigned char valueOp) # imm == unsigned ; disp == signed; stdAllowOverride==True, stdValueOp==OPCODE_SAVE
    cdef unsigned short modSegLoad(self, tuple rmOperands, unsigned char regSize) # imm == unsigned ; disp == signed
    cdef unsigned short modSegSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value) # imm == unsigned ; disp == signed
    cdef long long modRLoad(self, tuple rmOperands, unsigned char regSize, unsigned char signed) # imm == unsigned ; disp == signed
    cdef unsigned long long modRSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value, unsigned char valueOp) # imm == unsigned ; disp == signed
    cdef unsigned short getRegValueWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize)
    cdef tuple sibOperands(self, unsigned char mod)
    cdef tuple modRMOperands(self, unsigned char regSize, unsigned char modRMflags) # imm == unsigned ; disp == signed ; regSize in bytes
    cdef tuple modRMOperandsResetEip(self, unsigned char regSize, unsigned char modRMflags)
    cdef unsigned char getCond(self, unsigned char index)
    cdef setFullFlags(self, long long reg0, long long reg1, unsigned char regSize, unsigned char method, unsigned char signed) # regSize in bits
    #cdef checkMemAccessRights(self, unsigned short segId, unsigned char write)
    cdef unsigned long long mmGetRealAddr(self, long long mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef bytes mmRead(self, long long mmAddr, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride)
    cdef long long mmReadValueSigned(self, long long mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long long mmReadValueUnsigned(self, long long mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef mmWrite(self, long long mmAddr, bytes data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long long mmWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long long mmWriteValueWithOp(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride, unsigned char valueOp)
    cdef unsigned long getBaseAddr(self, unsigned short segId)
    cdef unsigned long getRealAddr(self, unsigned short segId, long long offsetAddr)
    cdef unsigned char getSegSize(self, unsigned short segId)
    cdef unsigned char isSegPresent(self, unsigned short segId)
    cdef unsigned char getOpSegSize(self, unsigned short segId)
    cdef unsigned char getAddrSegSize(self, unsigned short segId)
    cdef tuple getOpAddrSegSize(self, unsigned short segId)
    cdef run(self)


