
from misc cimport Misc
from mm cimport Mm, ConfigSpace
from segments cimport Segment, GdtEntry, Gdt, Idt, Segments

cdef class ModRMClass:
    cpdef object main
    cdef Registers registers
    cdef unsigned char rm, reg, mod, ss
    cdef unsigned short rmName0, rmName1, rmNameSegId, regName
    cdef signed long int rmName2
    cpdef object modRMOperands(self, unsigned char regSize, unsigned char modRMflags)
    cdef unsigned int getRMValueFull(self, unsigned char rmSize)
    cpdef object modRMLoadSigned(self, unsigned char regSize, unsigned char allowOverride)
    cpdef object modRMLoadUnsigned(self, unsigned char regSize, unsigned char allowOverride)
    cpdef object modRMSave(self, unsigned char regSize, unsigned long int value, unsigned char allowOverride, unsigned char valueOp) # stdAllowOverride==True, stdValueOp==OPCODE_SAVE
    cdef signed long int modRLoadSigned(self, unsigned char regSize)
    cdef unsigned long int modRLoadUnsigned(self, unsigned char regSize)
    cdef unsigned long int modRSave(self, unsigned char regSize, unsigned long int value, unsigned char valueOp)



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
    cdef signed long int getCurrentOpcodeSigned(self, unsigned char numBytes)
    cdef unsigned long int getCurrentOpcodeUnsigned(self, unsigned char numBytes)
    cdef signed long int getCurrentOpcodeAddSigned(self, unsigned char numBytes)
    cdef unsigned long int getCurrentOpcodeAddUnsigned(self, unsigned char numBytes)
    cdef unsigned char getCurrentOpcodeAddWithAddr(self, unsigned short *retSeg, unsigned int *retAddr)
    cdef unsigned short segRead(self, unsigned short segId)
    cdef unsigned short segWrite(self, unsigned short segId, unsigned short segValue)
    cdef signed long int regReadSigned(self, unsigned short regId)
    cdef unsigned long int regReadUnsigned(self, unsigned short regId)
    cdef unsigned int regWrite(self, unsigned short regId, unsigned int value)
    cdef unsigned int regAdd(self, unsigned short regId, unsigned int value)
    cdef unsigned int regAdc(self, unsigned short regId, unsigned int value)
    cdef unsigned int regSub(self, unsigned short regId, unsigned int value)
    cdef unsigned int regSbb(self, unsigned short regId, unsigned int value)
    cdef unsigned int regXor(self, unsigned short regId, unsigned int value)
    cdef unsigned int regAnd(self, unsigned short regId, unsigned int value)
    cdef unsigned int regOr (self, unsigned short regId, unsigned int value)
    cdef unsigned int regNeg(self, unsigned short regId)
    cdef unsigned int regNot(self, unsigned short regId)
    cdef unsigned int regWriteWithOp(self, unsigned short regId, unsigned int value, unsigned char valueOp)
    cdef unsigned int valSetBit(self, unsigned int value, unsigned char bit, unsigned char state)
    cdef unsigned char valGetBit(self, unsigned int value, unsigned char bit) # return True if bit is set, otherwise False
    cdef unsigned int getEFLAG(self, unsigned int flags)
    cdef unsigned int setEFLAG(self, unsigned int flags, unsigned char flagState)
    cdef unsigned int getFlag(self, unsigned short regId, unsigned int flags)
    cdef unsigned short getWordAsDword(self, unsigned short regWord, unsigned char wantRegSize)
    cdef void setSZP(self, unsigned int value, unsigned char regSize)
    cdef void setSZP_O0(self, unsigned int value, unsigned char regSize)
    cdef void setSZP_C0_O0_A0(self, unsigned int value, unsigned char regSize)
    cdef unsigned short getRegNameWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize)
    cdef unsigned char getCond(self, unsigned char index)
    cdef void setFullFlags(self, unsigned long int reg0, unsigned long int reg1, unsigned char regSize, unsigned char method)
    cpdef checkMemAccessRights(self, unsigned int mmAddr, unsigned int dataSize, unsigned short segId, unsigned char write)
    cdef unsigned int mmGetRealAddr(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef bytes mmRead(self, unsigned int mmAddr, unsigned int dataSize, unsigned short segId, unsigned char allowOverride)
    cdef signed long int mmReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long int mmReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef void mmWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long int mmWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long int mmWriteValueWithOp(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize, unsigned short segId, unsigned char allowOverride, unsigned char valueOp)
    cdef unsigned char getSegSize(self, unsigned short segId)
    cdef unsigned char isSegPresent(self, unsigned short segId)
    cdef unsigned char getOpSegSize(self, unsigned short segId)
    cdef unsigned char getAddrSegSize(self, unsigned short segId)
    cdef unsigned char getOpCodeSegSize(self)
    cdef unsigned char getAddrCodeSegSize(self)
    cdef void getOpAddrSegSize(self, unsigned short segId, unsigned char *opSize, unsigned char *addrSize)
    cdef void getOpAddrCodeSegSize(self, unsigned char *opSize, unsigned char *addrSize)
    cdef void run(self)


