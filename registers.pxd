
from misc cimport Misc
from mm cimport Mm
from segments cimport Segment, GdtEntry, Gdt, Idt, Paging, Segments

include "globals.pxi"
include "cpu_globals.pxi"

ctypedef fused unsigned_value_types:
    unsigned char
    unsigned short
    unsigned int
    unsigned long int

ctypedef unsigned char unsigned_char
ctypedef unsigned short unsigned_short
ctypedef unsigned int unsigned_int
ctypedef unsigned long int unsigned_long_int



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
    cdef unsigned short modRMOperands(self, unsigned char regSize, unsigned char modRMflags) except -1
    cdef unsigned long int getRMValueFull(self, unsigned char rmSize)
    cdef signed long int modRMLoadSigned(self, unsigned char regSize, unsigned char allowOverride) except? -1
    cdef unsigned long int modRMLoadUnsigned(self, unsigned char regSize, unsigned char allowOverride) except -1
    cdef unsigned long int modRMSave(self, unsigned char regSize, unsigned long int value, unsigned char allowOverride, unsigned char valueOp) except -1 # stdAllowOverride==True, stdValueOp==OPCODE_SAVE
    cdef signed long int modRLoadSigned(self, unsigned char regSize)
    cdef unsigned long int modRLoadUnsigned(self, unsigned char regSize)
    cdef unsigned long int modRSave(self, unsigned char regSize, unsigned long int value, unsigned char valueOp)



cdef class Registers:
    cpdef object main
    cdef Registers registers
    cdef Segments segments
    cdef RegStruct regs[CPU_REGISTERS]
    cdef public unsigned char repPrefix, segmentOverridePrefix, operandSizePrefix, \
                                addressSizePrefix, codeSegSize, cf, pf, af, zf, sf, \
                                tf, if_flag, df, of, iopl, nt, rf, vm, ac, vif, vip, id, cpl
    cdef unsigned char operSize, addrSize
    cdef void reset(self)
    cdef void resetPrefixes(self)
    cdef inline void readCodeSegSize(self):
        self.getOpAddrCodeSegSize(&self.operSize, &self.addrSize)
    cdef unsigned int readFlags(self)
    cdef void setFlags(self, unsigned int flags)
    cdef unsigned char getCPL(self)
    cdef unsigned char getIOPL(self)
    cdef signed char getCurrentOpcodeSignedByte(self)
    cdef signed short getCurrentOpcodeSignedWord(self)
    cdef signed int getCurrentOpcodeSignedDword(self)
    cdef signed long int getCurrentOpcodeSignedQword(self)
    cdef signed long int getCurrentOpcodeSigned(self, unsigned char numBytes)
    cdef unsigned char getCurrentOpcodeUnsignedByte(self)
    cdef unsigned short getCurrentOpcodeUnsignedWord(self)
    cdef unsigned int getCurrentOpcodeUnsignedDword(self)
    cdef unsigned long int getCurrentOpcodeUnsignedQword(self)
    cdef unsigned long int getCurrentOpcodeUnsigned(self, unsigned char numBytes)
    cdef signed char getCurrentOpcodeAddSignedByte(self)
    cdef signed short getCurrentOpcodeAddSignedWord(self)
    cdef signed int getCurrentOpcodeAddSignedDword(self)
    cdef signed long int getCurrentOpcodeAddSignedQword(self)
    cdef signed long int getCurrentOpcodeAddSigned(self, unsigned char numBytes)
    cdef unsigned char getCurrentOpcodeAddUnsignedByte(self)
    cdef unsigned short getCurrentOpcodeAddUnsignedWord(self)
    cdef unsigned int getCurrentOpcodeAddUnsignedDword(self)
    cdef unsigned long int getCurrentOpcodeAddUnsignedQword(self)
    cdef unsigned long int getCurrentOpcodeAddUnsigned(self, unsigned char numBytes)
    cdef unsigned char getCurrentOpcodeAddWithAddr(self, unsigned short *retSeg, unsigned int *retAddr)
    cdef unsigned short segRead(self, unsigned short segId)
    cdef unsigned short segWrite(self, unsigned short segId, unsigned short segValue)
    cdef inline signed char regReadSignedLowByte(self, unsigned short regId):
        return <signed char>self.regs[regId]._union.word._union.byte.rl
    cdef inline signed char regReadSignedHighByte(self, unsigned short regId):
        return <signed char>self.regs[regId]._union.word._union.byte.rh
    cdef inline signed short regReadSignedWord(self, unsigned short regId):
        return <signed short>self.regs[regId]._union.word._union.rx
    cdef inline signed int regReadSignedDword(self, unsigned short regId):
        return <signed int>self.regs[regId]._union.dword.erx
    cdef inline signed long int regReadSignedQword(self, unsigned short regId):
        return <signed long int>self.regs[regId]._union.rrx
    cdef inline unsigned char regReadUnsignedLowByte(self, unsigned short regId):
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline unsigned char regReadUnsignedHighByte(self, unsigned short regId):
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline unsigned short regReadUnsignedWord(self, unsigned short regId):
        return self.regs[regId]._union.word._union.rx
    cdef inline unsigned int regReadUnsignedDword(self, unsigned short regId):
        return self.regs[regId]._union.dword.erx
    cdef inline unsigned long int regReadUnsignedQword(self, unsigned short regId):
        return self.regs[regId]._union.rrx
    cdef inline unsigned char regWriteLowByte(self, unsigned short regId, unsigned char value):
        self.regs[regId]._union.word._union.byte.rl = value
        return value # returned value is unsigned!!
    cdef inline unsigned char regWriteHighByte(self, unsigned short regId, unsigned char value):
        self.regs[regId]._union.word._union.byte.rh = value
        return value # returned value is unsigned!!
    cdef inline unsigned short regWriteWord(self, unsigned short regId, unsigned short value):
        self.regs[regId]._union.word._union.rx = value
        return value # returned value is unsigned!!
    cdef inline unsigned int regWriteDword(self, unsigned short regId, unsigned int value):
        self.regs[regId]._union.dword.erx = value
        return value # returned value is unsigned!!
    cdef inline unsigned short regWriteWordFlags(self, unsigned short value):
        self.setFlags(value)
        self.regs[CPU_REGISTER_FLAGS]._union.word._union.rx = value
        return value # returned value is unsigned!!
    cdef inline unsigned int regWriteDwordEflags(self, unsigned int value):
        self.setFlags(value)
        self.regs[CPU_REGISTER_EFLAGS]._union.dword.erx = value
        return value # returned value is unsigned!!
    cdef inline unsigned long int regWriteQword(self, unsigned short regId, unsigned long int value):
        if (regId == CPU_REGISTER_RFLAGS):
            self.setFlags(<unsigned int>value)
        else:
            self.regs[regId]._union.rrx = value
        return value # returned value is unsigned!!
    cdef signed long int regReadSigned(self, unsigned short regId, unsigned char regSize)
    cdef unsigned long int regReadUnsigned(self, unsigned short regId, unsigned char regSize)
    cdef unsigned long int regWrite(self, unsigned short regId, unsigned long int value, unsigned char regSize)
    cdef inline unsigned char regAddLowByte(self, unsigned short regId, unsigned char value):
        return self.regWriteLowByte(regId, (self.regReadUnsignedLowByte(regId)+value))
    cdef inline unsigned char regAddHighByte(self, unsigned short regId, unsigned char value):
        return self.regWriteHighByte(regId, (self.regReadUnsignedHighByte(regId)+value))
    cdef inline unsigned short regAddWord(self, unsigned short regId, unsigned short value):
        return self.regWriteWord(regId, (self.regReadUnsignedWord(regId)+value))
    cdef inline unsigned int regAddDword(self, unsigned short regId, unsigned int value):
        return self.regWriteDword(regId, (self.regReadUnsignedDword(regId)+value))
    cdef inline unsigned long int regAddQword(self, unsigned short regId, unsigned long int value):
        return self.regWriteQword(regId, (self.regReadUnsignedQword(regId)+value))
    cdef unsigned long int regAdd(self, unsigned short regId, unsigned long int value, unsigned char regSize)
    cdef inline unsigned char regAdcLowByte(self, unsigned short regId, unsigned char value):
        return self.regAddLowByte(regId, (value+self.cf))
    cdef inline unsigned char regAdcHighByte(self, unsigned short regId, unsigned char value):
        return self.regAddHighByte(regId, (value+self.cf))
    cdef inline unsigned short regAdcWord(self, unsigned short regId, unsigned short value):
        return self.regAddWord(regId, (value+self.cf))
    cdef inline unsigned int regAdcDword(self, unsigned short regId, unsigned int value):
        return self.regAddDword(regId, (value+self.cf))
    cdef inline unsigned long int regAdcQword(self, unsigned short regId, unsigned long int value):
        return self.regAddQword(regId, (value+self.cf))
    cdef inline unsigned char regSubLowByte(self, unsigned short regId, unsigned char value):
        return self.regWriteLowByte(regId, (self.regReadUnsignedLowByte(regId)-value))
    cdef inline unsigned char regSubHighByte(self, unsigned short regId, unsigned char value):
        return self.regWriteHighByte(regId, (self.regReadUnsignedHighByte(regId)-value))
    cdef inline unsigned short regSubWord(self, unsigned short regId, unsigned short value):
        return self.regWriteWord(regId, (self.regReadUnsignedWord(regId)-value))
    cdef inline unsigned int regSubDword(self, unsigned short regId, unsigned int value):
        return self.regWriteDword(regId, (self.regReadUnsignedDword(regId)-value))
    cdef inline unsigned long int regSubQword(self, unsigned short regId, unsigned long int value):
        return self.regWriteQword(regId, (self.regReadUnsignedQword(regId)-value))
    cdef unsigned long int regSub(self, unsigned short regId, unsigned long int value, unsigned char regSize)
    cdef inline unsigned char regSbbLowByte(self, unsigned short regId, unsigned char value):
        return self.regSubLowByte(regId, (value+self.cf))
    cdef inline unsigned char regSbbHighByte(self, unsigned short regId, unsigned char value):
        return self.regSubHighByte(regId, (value+self.cf))
    cdef inline unsigned short regSbbWord(self, unsigned short regId, unsigned short value):
        return self.regSubWord(regId, (value+self.cf))
    cdef inline unsigned int regSbbDword(self, unsigned short regId, unsigned int value):
        return self.regSubDword(regId, (value+self.cf))
    cdef inline unsigned long int regSbbQword(self, unsigned short regId, unsigned long int value):
        return self.regSubQword(regId, (value+self.cf))
    cdef inline unsigned char regXorLowByte(self, unsigned short regId, unsigned char value):
        return self.regWriteLowByte(regId, (self.regReadUnsignedLowByte(regId)^value))
    cdef inline unsigned char regXorHighByte(self, unsigned short regId, unsigned char value):
        return self.regWriteHighByte(regId, (self.regReadUnsignedHighByte(regId)^value))
    cdef inline unsigned short regXorWord(self, unsigned short regId, unsigned short value):
        return self.regWriteWord(regId, (self.regReadUnsignedWord(regId)^value))
    cdef inline unsigned int regXorDword(self, unsigned short regId, unsigned int value):
        return self.regWriteDword(regId, (self.regReadUnsignedDword(regId)^value))
    cdef inline unsigned long int regXorQword(self, unsigned short regId, unsigned long int value):
        return self.regWriteQword(regId, (self.regReadUnsignedQword(regId)^value))
    cdef inline unsigned char regAndLowByte(self, unsigned short regId, unsigned char value):
        return self.regWriteLowByte(regId, (self.regReadUnsignedLowByte(regId)&value))
    cdef inline unsigned char regAndHighByte(self, unsigned short regId, unsigned char value):
        return self.regWriteHighByte(regId, (self.regReadUnsignedHighByte(regId)&value))
    cdef inline unsigned short regAndWord(self, unsigned short regId, unsigned short value):
        return self.regWriteWord(regId, (self.regReadUnsignedWord(regId)&value))
    cdef inline unsigned int regAndDword(self, unsigned short regId, unsigned int value):
        return self.regWriteDword(regId, (self.regReadUnsignedDword(regId)&value))
    cdef inline unsigned long int regAndQword(self, unsigned short regId, unsigned long int value):
        return self.regWriteQword(regId, (self.regReadUnsignedQword(regId)&value))
    cdef inline unsigned char regOrLowByte(self, unsigned short regId, unsigned char value):
        return self.regWriteLowByte(regId, (self.regReadUnsignedLowByte(regId)|value))
    cdef inline unsigned char regOrHighByte(self, unsigned short regId, unsigned char value):
        return self.regWriteHighByte(regId, (self.regReadUnsignedHighByte(regId)|value))
    cdef inline unsigned short regOrWord(self, unsigned short regId, unsigned short value):
        return self.regWriteWord(regId, (self.regReadUnsignedWord(regId)|value))
    cdef inline unsigned int regOrDword(self, unsigned short regId, unsigned int value):
        return self.regWriteDword(regId, (self.regReadUnsignedDword(regId)|value))
    cdef inline unsigned long int regOrQword(self, unsigned short regId, unsigned long int value):
        return self.regWriteQword(regId, (self.regReadUnsignedQword(regId)|value))
    cdef inline unsigned char regNegLowByte(self, unsigned short regId):
        return self.regWriteLowByte(regId, (-self.regReadUnsignedLowByte(regId)))
    cdef inline unsigned char regNegHighByte(self, unsigned short regId):
        return self.regWriteHighByte(regId, (-self.regReadUnsignedHighByte(regId)))
    cdef inline unsigned short regNegWord(self, unsigned short regId):
        return self.regWriteWord(regId, (-self.regReadUnsignedWord(regId)))
    cdef inline unsigned int regNegDword(self, unsigned short regId):
        return self.regWriteDword(regId, (-self.regReadUnsignedDword(regId)))
    cdef inline unsigned long int regNegQword(self, unsigned short regId):
        return self.regWriteQword(regId, (-self.regReadUnsignedQword(regId)))
    cdef inline unsigned char regNotLowByte(self, unsigned short regId):
        return self.regWriteLowByte(regId, (~self.regReadUnsignedLowByte(regId)))
    cdef inline unsigned char regNotHighByte(self, unsigned short regId):
        return self.regWriteHighByte(regId, (~self.regReadUnsignedHighByte(regId)))
    cdef inline unsigned short regNotWord(self, unsigned short regId):
        return self.regWriteWord(regId, (~self.regReadUnsignedWord(regId)))
    cdef inline unsigned int regNotDword(self, unsigned short regId):
        return self.regWriteDword(regId, (~self.regReadUnsignedDword(regId)))
    cdef inline unsigned long int regNotQword(self, unsigned short regId):
        return self.regWriteQword(regId, (~self.regReadUnsignedQword(regId)))
    cdef unsigned char regWriteWithOpLowByte(self, unsigned short regId, unsigned char value, unsigned char valueOp)
    cdef unsigned char regWriteWithOpHighByte(self, unsigned short regId, unsigned char value, unsigned char valueOp)
    cdef unsigned short regWriteWithOpWord(self, unsigned short regId, unsigned short value, unsigned char valueOp)
    cdef unsigned int regWriteWithOpDword(self, unsigned short regId, unsigned int value, unsigned char valueOp)
    cdef unsigned long int regWriteWithOpQword(self, unsigned short regId, unsigned long int value, unsigned char valueOp)
    cdef inline unsigned char valGetBit(self, unsigned int value, unsigned char bit): # return True if bit is set, otherwise False
        return (value&<unsigned int>(1<<bit))!=0
    cdef inline unsigned int valSetBit(self, unsigned int value, unsigned char bit, unsigned char state):
        if (state):
            return ( value | <unsigned int>(1<<bit) )
        return ( value & <unsigned int>(~(1<<bit)) )
    cdef inline unsigned int clearEFLAG(self, unsigned int flags):
        self.regWriteDwordEflags(self.readFlags() & (~flags))
    cdef inline unsigned int getFlagDword(self, unsigned short regId, unsigned int flags):
        return (self.regReadUnsignedDword(regId)&flags)
    cdef void setSZP(self, unsigned int value, unsigned char regSize)
    cdef void setSZP_O(self, unsigned int value, unsigned char regSize)
    cdef void setSZP_A(self, unsigned int value, unsigned char regSize)
    cdef void setSZP_COA(self, unsigned int value, unsigned char regSize)
    cdef unsigned short getRegNameWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize) except -1
    cdef unsigned char getCond(self, unsigned char index)
    cdef void setFullFlags(self, unsigned long int reg0, unsigned long int reg1, unsigned char regSize, unsigned char method)
    #cpdef checkMemAccessRights(self, unsigned int mmAddr, unsigned int dataSize, unsigned short segId, unsigned char write)
    cdef unsigned int mmGetRealAddr(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef bytes mmRead(self, unsigned int mmAddr, unsigned int dataSize, unsigned short segId, unsigned char allowOverride)
    cdef signed char mmReadValueSignedByte(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef signed short mmReadValueSignedWord(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef signed int mmReadValueSignedDword(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef signed long int mmReadValueSignedQword(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef signed long int mmReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned char mmReadValueUnsignedByte(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef unsigned short mmReadValueUnsignedWord(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef unsigned int mmReadValueUnsignedDword(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long int mmReadValueUnsignedQword(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride)
    cdef unsigned long int mmReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned char mmWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned char mmWriteValueSize(self, unsigned int mmAddr, unsigned_value_types data, unsigned short segId, unsigned char allowOverride)
    cdef unsigned char mmWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize, unsigned short segId, unsigned char allowOverride)
    cdef unsigned_value_types mmWriteValueWithOpSize(self, unsigned int mmAddr, unsigned_value_types data, unsigned short segId, unsigned char allowOverride, unsigned char valueOp)
    cdef void switchTSS(self)
    cdef inline unsigned char getSegSize(self, unsigned short segId):
        return (<Segment>(self.segments.getSegmentInstance(segId, True))).getSegSize()
    cdef inline unsigned char isSegPresent(self, unsigned short segId):
        return (((<Segment>(self.segments.getSegmentInstance(segId, True))).accessByte & GDT_ACCESS_PRESENT) != 0)
    cdef inline unsigned char getAddrSegSize(self, unsigned short segId):
        segId = self.getSegSize(segId)&BITMASK_BYTE
        return ((((segId==OP_SIZE_WORD)==self.addressSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
    cdef inline void getOpAddrCodeSegSize(self, unsigned char *opSize, unsigned char *addrSize):
        opSize[0]   = ((((self.codeSegSize==OP_SIZE_WORD)==self.operandSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
        addrSize[0] = ((((self.codeSegSize==OP_SIZE_WORD)==self.addressSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
    cdef void run(self)


