
from misc cimport Misc
from mm cimport Mm, ConfigSpace
from segments cimport Segment, GdtEntry, Gdt, Idt, Segments

cdef class ModRMClass:
    cpdef object main
    cdef Registers registers
    cdef unsigned char rm, reg, mod, ss
    cdef unsigned short rmName0, rmName1, rmNameSegId, regName
    cdef signed long long rmName2
    cdef void modRMOperands(self, unsigned char regSize, unsigned char modRMflags)
    cdef unsigned long getRMValueFull(self, unsigned char rmSize)
    cdef signed long long modRMLoadSigned(self, unsigned char regSize, unsigned char allowOverride)
    cdef unsigned long long modRMLoadUnsigned(self, unsigned char regSize, unsigned char allowOverride)
    cdef unsigned long long modRMSave(self, unsigned char regSize, unsigned long long value, unsigned char allowOverride, unsigned char valueOp) # stdAllowOverride==True, stdValueOp==OPCODE_SAVE
    cdef signed long long modRLoadSigned(self, unsigned char regSize)
    cdef unsigned long long modRLoadUnsigned(self, unsigned char regSize)
    cdef unsigned long long modRSave(self, unsigned char regSize, unsigned long long value, unsigned char valueOp)



cdef class Registers:
    cpdef object main
    cdef Segments segments
    cdef public ConfigSpace regs
    cdef public unsigned char repPrefix, segmentOverridePrefix, operandSizePrefix, \
                                addressSizePrefix, codeSegSize
    cdef unsigned char operSize, addrSize
    cdef public unsigned short eipSizeRegId
    cdef void reset(self)
    cdef void resetPrefixes(self)
    cdef void readCodeSegSize(self)
    cdef unsigned char getCPL(self)
    cdef unsigned char getIOPL(self)
    cdef unsigned char getRegSize(self, unsigned short regId)
    cdef signed long long getCurrentOpcodeSigned(self, unsigned char numBytes)
    cdef unsigned long long getCurrentOpcodeUnsigned(self, unsigned char numBytes)
    cdef signed long long getCurrentOpcodeAddSigned(self, unsigned char numBytes)
    cdef unsigned long long getCurrentOpcodeAddUnsigned(self, unsigned char numBytes)
    cdef unsigned char getCurrentOpcodeAddWithAddr(self, unsigned short *retSeg, unsigned long *retAddr)
    cdef unsigned short segRead(self, unsigned short segId)
    cdef unsigned short segWrite(self, unsigned short segId, unsigned short segValue)
    cdef signed long long regReadSigned(self, unsigned short regId)
    cdef unsigned long long regReadUnsigned(self, unsigned short regId)
    cdef unsigned long regWrite(self, unsigned short regId, unsigned long value)
    cdef unsigned long regAdd(self, unsigned short regId, unsigned long value)
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
    cdef void setSZP(self, unsigned long value, unsigned char regSize)
    cdef void setSZP_O0(self, unsigned long value, unsigned char regSize)
    cdef void setSZP_C0_O0_A0(self, unsigned long value, unsigned char regSize)
    cdef unsigned short getRegNameWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize)
    cdef unsigned char getCond(self, unsigned char index)
    cdef void setFullFlags(self, unsigned long long reg0, unsigned long long reg1, unsigned char regSize, unsigned char method)
    cdef void checkMemAccessRights(self, unsigned long mmAddr, unsigned long dataSize, unsigned short segId, unsigned char write)
    cdef unsigned long mmGetRealAddr(self, unsigned long mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef bytes mmRead(self, unsigned long mmAddr, unsigned long dataSize, unsigned short segId, unsigned char allowOverride)
    cdef long long mmReadValueSigned(self, unsigned long mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long long mmReadValueUnsigned(self, unsigned long mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef void mmWrite(self, unsigned long mmAddr, bytes data, unsigned long dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long long mmWriteValue(self, unsigned long mmAddr, unsigned long long data, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long long mmWriteValueWithOp(self, unsigned long mmAddr, unsigned long long data, unsigned char dataSize, unsigned short segId, unsigned char allowOverride, unsigned char valueOp)
    cdef unsigned char getSegSize(self, unsigned short segId)
    cdef unsigned char isSegPresent(self, unsigned short segId)
    cdef unsigned char getOpSegSize(self, unsigned short segId)
    cdef unsigned char getAddrSegSize(self, unsigned short segId)
    cdef unsigned char getOpCodeSegSize(self)
    cdef unsigned char getAddrCodeSegSize(self)
    cdef void getOpAddrSegSize(self, unsigned short segId, unsigned char *opSize, unsigned char *addrSize)
    cdef void getOpAddrCodeSegSize(self, unsigned char *opSize, unsigned char *addrSize)
    cdef void run(self)


