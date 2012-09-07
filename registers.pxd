
from misc cimport Misc
from mm cimport Mm
from segments cimport Segment, GdtEntry, Gdt, Idt, Paging, Segments

DEF CPU_REGISTERS = 27

cdef:
    struct byteStruct:
        unsigned char rl
        unsigned char rh

    ctypedef union wordUnion:
        byteStruct byte
        unsigned short rx

    struct wordStruct:
        wordUnion _union
        unsigned short notUsed1
        unsigned int notUsed2

    struct dwordStruct:
        unsigned int erx
        unsigned int notUsed1

    ctypedef union qwordUnion:
        unsigned long int rrx
        dwordStruct dword
        wordStruct word

    struct RegStruct:
        qwordUnion _union


cdef class ModRMClass:
    cpdef object main
    cdef Registers registers
    cdef unsigned char rm, reg, mod, ss, regSize
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
    cdef Registers registers
    cdef Segments segments
    cdef RegStruct regs[CPU_REGISTERS]
    cdef public unsigned char repPrefix, segmentOverridePrefix, operandSizePrefix, \
                                addressSizePrefix, codeSegSize
    cdef unsigned char operSize, addrSize
    cdef public unsigned short eipSize
    cdef void reset(self)
    cdef void resetPrefixes(self)
    cdef void readCodeSegSize(self)
    cdef unsigned char getCPL(self)
    cdef unsigned char getIOPL(self)
    cdef signed long int getCurrentOpcodeSigned(self, unsigned char numBytes)
    cdef unsigned long int getCurrentOpcodeUnsigned(self, unsigned char numBytes)
    cdef signed long int getCurrentOpcodeAddSigned(self, unsigned char numBytes)
    cdef unsigned long int getCurrentOpcodeAddUnsigned(self, unsigned char numBytes)
    cdef unsigned char getCurrentOpcodeAddWithAddr(self, unsigned short *retSeg, unsigned int *retAddr)
    cdef unsigned short segRead(self, unsigned short segId)
    cdef unsigned short segWrite(self, unsigned short segId, unsigned short segValue)
    cdef signed char regReadSignedLowByte(self, unsigned short regId)
    cdef signed char regReadSignedHighByte(self, unsigned short regId)
    cdef signed short regReadSignedWord(self, unsigned short regId)
    cdef signed int regReadSignedDword(self, unsigned short regId)
    cdef signed long int regReadSignedQword(self, unsigned short regId)
    cdef signed long int regReadSigned(self, unsigned short regId, unsigned char regSize)
    cdef unsigned char regReadUnsignedLowByte(self, unsigned short regId)
    cdef unsigned char regReadUnsignedHighByte(self, unsigned short regId)
    cdef unsigned short regReadUnsignedWord(self, unsigned short regId)
    cdef unsigned int regReadUnsignedDword(self, unsigned short regId)
    cdef unsigned long int regReadUnsignedQword(self, unsigned short regId)
    cdef unsigned long int regReadUnsigned(self, unsigned short regId, unsigned char regSize)
    cdef unsigned char regWriteLowByte(self, unsigned short regId, unsigned char value)
    cdef unsigned char regWriteHighByte(self, unsigned short regId, unsigned char value)
    cdef unsigned short regWriteWord(self, unsigned short regId, unsigned short value)
    cdef unsigned int regWriteDword(self, unsigned short regId, unsigned int value)
    cdef unsigned long int regWriteQword(self, unsigned short regId, unsigned long int value)
    cdef unsigned long int regWrite(self, unsigned short regId, unsigned long int value, unsigned char regSize)
    cdef unsigned char regAddLowByte(self, unsigned short regId, unsigned char value)
    cdef unsigned char regAddHighByte(self, unsigned short regId, unsigned char value)
    cdef unsigned short regAddWord(self, unsigned short regId, unsigned short value)
    cdef unsigned int regAddDword(self, unsigned short regId, unsigned int value)
    cdef unsigned long int regAddQword(self, unsigned short regId, unsigned long int value)
    cdef unsigned long int regAdd(self, unsigned short regId, unsigned long int value, unsigned char regSize)
    cdef unsigned char regAdcLowByte(self, unsigned short regId, unsigned char value)
    cdef unsigned char regAdcHighByte(self, unsigned short regId, unsigned char value)
    cdef unsigned short regAdcWord(self, unsigned short regId, unsigned short value)
    cdef unsigned int regAdcDword(self, unsigned short regId, unsigned int value)
    cdef unsigned long int regAdcQword(self, unsigned short regId, unsigned long int value)
    cdef unsigned char regSubLowByte(self, unsigned short regId, unsigned char value)
    cdef unsigned char regSubHighByte(self, unsigned short regId, unsigned char value)
    cdef unsigned short regSubWord(self, unsigned short regId, unsigned short value)
    cdef unsigned int regSubDword(self, unsigned short regId, unsigned int value)
    cdef unsigned long int regSubQword(self, unsigned short regId, unsigned long int value)
    cdef unsigned long int regSub(self, unsigned short regId, unsigned long int value, unsigned char regSize)
    cdef unsigned char regSbbLowByte(self, unsigned short regId, unsigned char value)
    cdef unsigned char regSbbHighByte(self, unsigned short regId, unsigned char value)
    cdef unsigned short regSbbWord(self, unsigned short regId, unsigned short value)
    cdef unsigned int regSbbDword(self, unsigned short regId, unsigned int value)
    cdef unsigned long int regSbbQword(self, unsigned short regId, unsigned long int value)
    cdef unsigned char regXorLowByte(self, unsigned short regId, unsigned char value)
    cdef unsigned char regXorHighByte(self, unsigned short regId, unsigned char value)
    cdef unsigned short regXorWord(self, unsigned short regId, unsigned short value)
    cdef unsigned int regXorDword(self, unsigned short regId, unsigned int value)
    cdef unsigned long int regXorQword(self, unsigned short regId, unsigned long int value)
    cdef unsigned char regAndLowByte(self, unsigned short regId, unsigned char value)
    cdef unsigned char regAndHighByte(self, unsigned short regId, unsigned char value)
    cdef unsigned short regAndWord(self, unsigned short regId, unsigned short value)
    cdef unsigned int regAndDword(self, unsigned short regId, unsigned int value)
    cdef unsigned long int regAndQword(self, unsigned short regId, unsigned long int value)
    cdef unsigned char regOrLowByte(self, unsigned short regId, unsigned char value)
    cdef unsigned char regOrHighByte(self, unsigned short regId, unsigned char value)
    cdef unsigned short regOrWord(self, unsigned short regId, unsigned short value)
    cdef unsigned int regOrDword(self, unsigned short regId, unsigned int value)
    cdef unsigned long int regOrQword(self, unsigned short regId, unsigned long int value)
    cdef unsigned char regNegLowByte(self, unsigned short regId)
    cdef unsigned char regNegHighByte(self, unsigned short regId)
    cdef unsigned short regNegWord(self, unsigned short regId)
    cdef unsigned int regNegDword(self, unsigned short regId)
    cdef unsigned long int regNegQword(self, unsigned short regId)
    cdef unsigned char regNotLowByte(self, unsigned short regId)
    cdef unsigned char regNotHighByte(self, unsigned short regId)
    cdef unsigned short regNotWord(self, unsigned short regId)
    cdef unsigned int regNotDword(self, unsigned short regId)
    cdef unsigned long int regNotQword(self, unsigned short regId)
    cdef unsigned char regWriteWithOpLowByte(self, unsigned short regId, unsigned char value, unsigned char valueOp)
    cdef unsigned char regWriteWithOpHighByte(self, unsigned short regId, unsigned char value, unsigned char valueOp)
    cdef unsigned short regWriteWithOpWord(self, unsigned short regId, unsigned short value, unsigned char valueOp)
    cdef unsigned int regWriteWithOpDword(self, unsigned short regId, unsigned int value, unsigned char valueOp)
    cdef unsigned long int regWriteWithOpQword(self, unsigned short regId, unsigned long int value, unsigned char valueOp)
    cdef unsigned long int regWriteWithOp(self, unsigned short regId, unsigned long int value, unsigned char valueOp, unsigned char regSize)
    cdef unsigned int valSetBit(self, unsigned int value, unsigned char bit, unsigned char state)
    cdef unsigned char valGetBit(self, unsigned int value, unsigned char bit) # return True if bit is set, otherwise False
    cdef unsigned int getEFLAG(self, unsigned int flags)
    cdef unsigned int setEFLAG(self, unsigned int flags, unsigned char flagState)
    cdef unsigned int getFlagDword(self, unsigned short regId, unsigned int flags)
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


