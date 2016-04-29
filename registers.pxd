
include "globals.pxi"
include "cpu_globals.pxi"

from hirnwichse_main cimport Hirnwichse
from mm cimport Mm
from segments cimport Segment, GdtEntry, Gdt, Idt, Paging, Segments

cdef extern from "hirnwichse_eflags.h":
    struct eflagsStruct:
        unsigned int cf
        unsigned int reserved_1
        unsigned int pf
        unsigned int reserved_3
        unsigned int af
        unsigned int reserved_5
        unsigned int zf
        unsigned int sf
        unsigned int tf
        unsigned int if_flag
        unsigned int df
        unsigned int of
        unsigned int iopl
        unsigned int nt
        unsigned int reserved_15
        unsigned int rf
        unsigned int vm
        unsigned int ac
        unsigned int vif
        unsigned int vip
        unsigned int id
        unsigned int reserved_22
        unsigned int reserved_23
        unsigned int reserved_24
        unsigned int reserved_25
        unsigned int reserved_26
        unsigned int reserved_27
        unsigned int reserved_28
        unsigned int reserved_29
        unsigned int reserved_30
        unsigned int reserved_31

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
        eflagsStruct eflags_struct

    struct RegStruct:
        qwordUnion _union


cdef class ModRMClass:
    cdef Registers registers
    cdef Segment *rmNameSeg
    cdef unsigned char rm, reg, mod, ss, regSize
    cdef unsigned short rmName0, rmName1, regName
    cdef signed long int rmName2
    cdef unsigned char modRMOperands(self, unsigned char regSize, unsigned char modRMflags) nogil except BITMASK_BYTE_CONST
    cdef unsigned long int getRMValueFull(self, unsigned char rmSize) nogil
    cdef signed long int modRMLoadSigned(self, unsigned char regSize) nogil except? BITMASK_BYTE_CONST
    cdef unsigned long int modRMLoadUnsigned(self, unsigned char regSize) nogil except? BITMASK_BYTE_CONST
    cdef unsigned long int modRMSave(self, unsigned char regSize, unsigned long int value, unsigned char valueOp) nogil except? BITMASK_BYTE_CONST # stdValueOp==OPCODE_SAVE
    cdef signed long int modRLoadSigned(self, unsigned char regSize) nogil
    cdef unsigned long int modRLoadUnsigned(self, unsigned char regSize) nogil
    cdef unsigned long int modRSave(self, unsigned char regSize, unsigned long int value, unsigned char valueOp) nogil


cdef class Fpu:
    cdef Hirnwichse main
    cdef Registers registers
    cdef list st
    cdef unsigned short ctrl, status, tag, dataSeg, instSeg, opcode
    cdef unsigned int dataPointer, instPointer
    cdef void reset(self, unsigned char fninit)
    cdef inline unsigned char getPrecision(self)
    cdef inline void setPrecision(self)
    cdef inline void setCtrl(self, unsigned short ctrl)
    cdef inline void setPointers(self, unsigned short opcode)
    cdef inline void setDataPointers(self, unsigned short dataSeg, unsigned int dataPointer)
    cdef inline void setTag(self, unsigned short index, unsigned char tag)
    cdef inline void setFlag(self, unsigned short index, unsigned char flag)
    cdef inline void setExc(self, unsigned short index, unsigned char flag)
    cdef inline void setC(self, unsigned short index, unsigned char flag)
    cdef inline unsigned char getIndex(self, unsigned char index)
    cdef inline void addTop(self, signed char index)
    cdef inline void setVal(self, unsigned char tempIndex, object data, unsigned char setFlags) # load
    cdef inline object getVal(self, unsigned char tempIndex) # store
    cdef inline void push(self, object data, unsigned char setFlags) # load
    cdef inline object pop(self) # store
    cdef void run(self)


cdef class Registers:
    cdef Hirnwichse main
    cdef Segments segments
    cdef Fpu fpu
    cdef RegStruct regs[CPU_REGISTERS]
    cdef unsigned char cpl, A20Active, protectedModeOn, pagingOn, writeProtectionOn, ssInhibit, cacheDisabled
    cdef unsigned short ldtr
    cdef unsigned int cpuCacheBase, cpuCacheIndex
    cdef bytes cpuCache
    cdef void reset(self) nogil
    cdef void reloadCpuCache(self)
    cdef inline void checkCache(self, unsigned int mmAddr, unsigned char dataSize): # called on a memory write; reload cache for self-modifying-code
        if (mmAddr >= self.cpuCacheBase and mmAddr+dataSize <= self.cpuCacheBase+CPU_CACHE_SIZE):
            self.reloadCpuCache()
    cdef inline void setA20Active(self, unsigned char A20Active) nogil:
        self.A20Active = A20Active
        IF CPU_CACHE_SIZE:
            self.reloadCpuCache()
    cdef signed long int readFromCacheAddSigned(self, unsigned char numBytes)
    cdef unsigned long int readFromCacheAddUnsigned(self, unsigned char numBytes)
    cdef unsigned long int readFromCacheUnsigned(self, unsigned char numBytes)
    cdef inline unsigned int readFlags(self) nogil:
        return ((self.regs[CPU_REGISTER_EFLAGS]._union.dword.erx & (~RESERVED_FLAGS_BITMASK)) | FLAG_REQUIRED)
    cdef inline unsigned char setFlags(self, unsigned int flags) nogil
    cdef inline unsigned char getCPL(self) nogil:
        if (not self.protectedModeOn):
            return 0
        elif (self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
            return 3
        return self.cpl
    cdef inline void syncCR0State(self) nogil:
        self.protectedModeOn = self.getFlagDword(CPU_REGISTER_CR0, CR0_FLAG_PE) != 0
    cdef unsigned char getCurrentOpcodeUnsignedByte(self) nogil except? BITMASK_BYTE_CONST
    cdef inline signed short getCurrentOpcodeAddSignedByte(self) nogil except? BITMASK_BYTE_CONST:
        return <signed char>self.getCurrentOpcodeAddUnsignedByte()
    cdef inline signed short getCurrentOpcodeAddSignedWord(self) nogil except? BITMASK_BYTE_CONST:
        return <signed short>self.getCurrentOpcodeAddUnsignedWord()
    cdef inline signed int getCurrentOpcodeAddSignedDword(self) nogil except? BITMASK_BYTE_CONST:
        return <signed int>self.getCurrentOpcodeAddUnsignedDword()
    cdef inline signed long int getCurrentOpcodeAddSignedQword(self) nogil except? BITMASK_BYTE_CONST:
        return <signed long int>self.getCurrentOpcodeAddUnsignedQword()
    cdef signed long int getCurrentOpcodeAddSigned(self, unsigned char numBytes) nogil except? BITMASK_BYTE_CONST
    cdef unsigned char getCurrentOpcodeAddUnsignedByte(self) nogil except? BITMASK_BYTE_CONST
    cdef unsigned short getCurrentOpcodeAddUnsignedWord(self) nogil except? BITMASK_BYTE_CONST
    cdef unsigned int getCurrentOpcodeAddUnsignedDword(self) nogil except? BITMASK_BYTE_CONST
    cdef unsigned long int getCurrentOpcodeAddUnsignedQword(self) nogil except? BITMASK_BYTE_CONST
    cdef unsigned long int getCurrentOpcodeAddUnsigned(self, unsigned char numBytes) nogil except? BITMASK_BYTE_CONST
    cdef inline unsigned short segRead(self, unsigned short segId) nogil:
        return self.regs[CPU_SEGMENT_BASE+segId]._union.word._union.rx
    cdef unsigned char segWrite(self, unsigned short segId, unsigned short segValue) nogil except BITMASK_BYTE_CONST
    cdef unsigned char segWriteSegment(self, Segment *segment, unsigned short segValue) nogil except BITMASK_BYTE_CONST
    cdef inline signed char regReadSignedLowByte(self, unsigned short regId) nogil:
        return <signed char>self.regs[regId]._union.word._union.byte.rl
    cdef inline signed char regReadSignedHighByte(self, unsigned short regId) nogil:
        return <signed char>self.regs[regId]._union.word._union.byte.rh
    cdef inline signed short regReadSignedWord(self, unsigned short regId) nogil:
        return <signed short>self.regs[regId]._union.word._union.rx
    cdef inline signed int regReadSignedDword(self, unsigned short regId) nogil:
        return <signed int>self.regs[regId]._union.dword.erx
    cdef inline signed long int regReadSignedQword(self, unsigned short regId) nogil:
        return <signed long int>self.regs[regId]._union.rrx
    cdef inline unsigned char regReadUnsignedLowByte(self, unsigned short regId) nogil:
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline unsigned char regReadUnsignedHighByte(self, unsigned short regId) nogil:
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline unsigned short regReadUnsignedWord(self, unsigned short regId) nogil:
        return self.regs[regId]._union.word._union.rx
    cdef inline unsigned int regReadUnsignedDword(self, unsigned short regId) nogil:
        return self.regs[regId]._union.dword.erx
    cdef inline unsigned long int regReadUnsignedQword(self, unsigned short regId) nogil:
        return self.regs[regId]._union.rrx
    cdef inline unsigned char regWriteLowByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rl = value
        return value # returned value is unsigned!!
    cdef inline unsigned char regWriteHighByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rh = value
        return value # returned value is unsigned!!
    cdef inline unsigned short regWriteWord(self, unsigned short regId, unsigned short value) nogil:
        if (regId == CPU_REGISTER_EFLAGS):
            value &= ~RESERVED_FLAGS_BITMASK
            value |= FLAG_REQUIRED
            self.setFlags(value)
        self.regs[regId]._union.word._union.rx = value
        return value # returned value is unsigned!!
    cdef unsigned int regWriteDword(self, unsigned short regId, unsigned int value) nogil except? BITMASK_BYTE_CONST
    cdef inline unsigned long int regWriteQword(self, unsigned short regId, unsigned long int value) nogil:
        IF 0:
        #if (regId == CPU_REGISTER_RFLAGS):
            self.setFlags(<unsigned int>value)
        #else:
        #ELSE:
        self.regs[regId]._union.rrx = value
        return value
    cdef signed long int regReadSigned(self, unsigned short regId, unsigned char regSize) nogil
    cdef unsigned long int regReadUnsigned(self, unsigned short regId, unsigned char regSize) nogil
    cdef void regWrite(self, unsigned short regId, unsigned long int value, unsigned char regSize) nogil
    cdef inline unsigned char regAddLowByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rl += value
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline unsigned char regAddHighByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rh += value
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline unsigned short regAddWord(self, unsigned short regId, unsigned short value) nogil:
        self.regs[regId]._union.word._union.rx += value
        return self.regs[regId]._union.word._union.rx
    cdef inline unsigned int regAddDword(self, unsigned short regId, unsigned int value) nogil:
        self.regs[regId]._union.dword.erx += value
        return self.regs[regId]._union.dword.erx
    cdef inline unsigned long int regAddQword(self, unsigned short regId, unsigned long int value) nogil:
        self.regs[regId]._union.rrx += value
        return self.regs[regId]._union.rrx
    cdef inline unsigned long int regAdd(self, unsigned short regId, unsigned long int value, unsigned char regSize) nogil
    cdef inline unsigned char regAdcLowByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rl += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline unsigned char regAdcHighByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rh += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline unsigned short regAdcWord(self, unsigned short regId, unsigned short value) nogil:
        self.regs[regId]._union.word._union.rx += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.word._union.rx
    cdef inline unsigned int regAdcDword(self, unsigned short regId, unsigned int value) nogil:
        self.regs[regId]._union.dword.erx += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.dword.erx
    cdef inline unsigned long int regAdcQword(self, unsigned short regId, unsigned long int value) nogil:
        self.regs[regId]._union.rrx += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.rrx
    cdef inline unsigned char regSubLowByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rl -= value
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline unsigned char regSubHighByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rh -= value
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline unsigned short regSubWord(self, unsigned short regId, unsigned short value) nogil:
        self.regs[regId]._union.word._union.rx -= value
        return self.regs[regId]._union.word._union.rx
    cdef inline unsigned int regSubDword(self, unsigned short regId, unsigned int value) nogil:
        self.regs[regId]._union.dword.erx -= value
        return self.regs[regId]._union.dword.erx
    cdef inline unsigned long int regSubQword(self, unsigned short regId, unsigned long int value) nogil:
        self.regs[regId]._union.rrx -= value
        return self.regs[regId]._union.rrx
    cdef inline unsigned long int regSub(self, unsigned short regId, unsigned long int value, unsigned char regSize) nogil
    cdef inline unsigned char regSbbLowByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rl -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline unsigned char regSbbHighByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rh -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline unsigned short regSbbWord(self, unsigned short regId, unsigned short value) nogil:
        self.regs[regId]._union.word._union.rx -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.word._union.rx
    cdef inline unsigned int regSbbDword(self, unsigned short regId, unsigned int value) nogil:
        self.regs[regId]._union.dword.erx -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.dword.erx
    cdef inline unsigned long int regSbbQword(self, unsigned short regId, unsigned long int value) nogil:
        self.regs[regId]._union.rrx -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.rrx
    cdef inline unsigned char regXorLowByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rl ^= value
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline unsigned char regXorHighByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rh ^= value
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline unsigned short regXorWord(self, unsigned short regId, unsigned short value) nogil:
        self.regs[regId]._union.word._union.rx ^= value
        return self.regs[regId]._union.word._union.rx
    cdef inline unsigned int regXorDword(self, unsigned short regId, unsigned int value) nogil:
        self.regs[regId]._union.dword.erx ^= value
        return self.regs[regId]._union.dword.erx
    cdef inline unsigned long int regXorQword(self, unsigned short regId, unsigned long int value) nogil:
        self.regs[regId]._union.rrx ^= value
        return self.regs[regId]._union.rrx
    cdef inline unsigned char regAndLowByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rl &= value
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline unsigned char regAndHighByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rh &= value
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline unsigned short regAndWord(self, unsigned short regId, unsigned short value) nogil:
        self.regs[regId]._union.word._union.rx &= value
        return self.regs[regId]._union.word._union.rx
    cdef inline unsigned int regAndDword(self, unsigned short regId, unsigned int value) nogil:
        self.regs[regId]._union.dword.erx &= value
        return self.regs[regId]._union.dword.erx
    cdef inline unsigned long int regAndQword(self, unsigned short regId, unsigned long int value) nogil:
        self.regs[regId]._union.rrx &= value
        return self.regs[regId]._union.rrx
    cdef inline unsigned char regOrLowByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rl |= value
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline unsigned char regOrHighByte(self, unsigned short regId, unsigned char value) nogil:
        self.regs[regId]._union.word._union.byte.rh |= value
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline unsigned short regOrWord(self, unsigned short regId, unsigned short value) nogil:
        self.regs[regId]._union.word._union.rx |= value
        return self.regs[regId]._union.word._union.rx
    cdef inline unsigned int regOrDword(self, unsigned short regId, unsigned int value) nogil:
        self.regs[regId]._union.dword.erx |= value
        return self.regs[regId]._union.dword.erx
    cdef inline unsigned long int regOrQword(self, unsigned short regId, unsigned long int value) nogil:
        self.regs[regId]._union.rrx |= value
        return self.regs[regId]._union.rrx
    cdef inline unsigned char regNegLowByte(self, unsigned short regId) nogil:
        self.regs[regId]._union.word._union.byte.rl = -(self.regs[regId]._union.word._union.byte.rl)
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline unsigned char regNegHighByte(self, unsigned short regId) nogil:
        self.regs[regId]._union.word._union.byte.rh = -(self.regs[regId]._union.word._union.byte.rh)
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline unsigned short regNegWord(self, unsigned short regId) nogil:
        self.regs[regId]._union.word._union.rx = -(self.regs[regId]._union.word._union.rx)
        return self.regs[regId]._union.word._union.rx
    cdef inline unsigned int regNegDword(self, unsigned short regId) nogil:
        self.regs[regId]._union.dword.erx = -(self.regs[regId]._union.dword.erx)
        return self.regs[regId]._union.dword.erx
    cdef inline unsigned long int regNegQword(self, unsigned short regId) nogil:
        self.regs[regId]._union.rrx = -(self.regs[regId]._union.rrx)
        return self.regs[regId]._union.rrx
    cdef inline unsigned char regNotLowByte(self, unsigned short regId) nogil:
        self.regs[regId]._union.word._union.byte.rl = ~(self.regs[regId]._union.word._union.byte.rl)
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline unsigned char regNotHighByte(self, unsigned short regId) nogil:
        self.regs[regId]._union.word._union.byte.rh = ~(self.regs[regId]._union.word._union.byte.rh)
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline unsigned short regNotWord(self, unsigned short regId) nogil:
        self.regs[regId]._union.word._union.rx = ~(self.regs[regId]._union.word._union.rx)
        return self.regs[regId]._union.word._union.rx
    cdef inline unsigned int regNotDword(self, unsigned short regId) nogil:
        self.regs[regId]._union.dword.erx = ~(self.regs[regId]._union.dword.erx)
        return self.regs[regId]._union.dword.erx
    cdef inline unsigned long int regNotQword(self, unsigned short regId) nogil:
        self.regs[regId]._union.rrx = ~(self.regs[regId]._union.rrx)
        return self.regs[regId]._union.rrx
    cdef inline unsigned char regWriteWithOpLowByte(self, unsigned short regId, unsigned char value, unsigned char valueOp) nogil
    cdef inline unsigned char regWriteWithOpHighByte(self, unsigned short regId, unsigned char value, unsigned char valueOp) nogil
    cdef inline unsigned short regWriteWithOpWord(self, unsigned short regId, unsigned short value, unsigned char valueOp) nogil
    cdef inline unsigned int regWriteWithOpDword(self, unsigned short regId, unsigned int value, unsigned char valueOp) nogil
    cdef inline unsigned long int regWriteWithOpQword(self, unsigned short regId, unsigned long int value, unsigned char valueOp) nogil
    cdef inline void clearEFLAG(self, unsigned int flags) nogil:
        self.regAndDword(CPU_REGISTER_EFLAGS, ~flags)
    cdef inline unsigned int getFlagDword(self, unsigned short regId, unsigned int flags) nogil:
        return (self.regReadUnsignedDword(regId)&flags)
    cdef inline void setSZP(self, unsigned int value, unsigned char regSize) nogil
    cdef inline void setSZP_O(self, unsigned int value, unsigned char regSize) nogil
    cdef inline void setSZP_A(self, unsigned int value, unsigned char regSize) nogil
    cdef inline void setSZP_COA(self, unsigned int value, unsigned char regSize) nogil
    cdef inline unsigned char getRegNameWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef inline unsigned char getCond(self, unsigned char index) nogil
    cdef inline void setFullFlags(self, unsigned long int reg0, unsigned long int reg1, unsigned char regSize, unsigned char method) nogil
    cdef inline unsigned int mmGetRealAddr(self, unsigned int mmAddr, unsigned int dataSize, Segment *segment, unsigned char allowOverride, unsigned char written) nogil except? BITMASK_BYTE_CONST
    cdef inline signed short mmReadValueSignedByte(self, unsigned int mmAddr, Segment *segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST:
        return <signed char>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
    cdef inline signed short mmReadValueSignedWord(self, unsigned int mmAddr, Segment *segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST:
        return <signed short>self.mmReadValueUnsignedWord(mmAddr, segment, allowOverride)
    cdef inline signed int mmReadValueSignedDword(self, unsigned int mmAddr, Segment *segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST:
        return <signed int>self.mmReadValueUnsignedDword(mmAddr, segment, allowOverride)
    cdef inline signed long int mmReadValueSignedQword(self, unsigned int mmAddr, Segment *segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST:
        return <signed long int>self.mmReadValueUnsignedQword(mmAddr, segment, allowOverride)
    cdef signed long int mmReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize, Segment *segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST
    cdef inline unsigned char mmReadValueUnsignedByte(self, unsigned int mmAddr, Segment *segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST
    cdef unsigned short mmReadValueUnsignedWord(self, unsigned int mmAddr, Segment *segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST
    cdef unsigned int mmReadValueUnsignedDword(self, unsigned int mmAddr, Segment *segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST
    cdef unsigned long int mmReadValueUnsignedQword(self, unsigned int mmAddr, Segment *segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST
    cdef unsigned long int mmReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize, Segment *segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST
    cdef unsigned char mmWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize, Segment *segment, unsigned char allowOverride) nogil except BITMASK_BYTE_CONST
    cdef unsigned long int mmWriteValueWithOp(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize, Segment *segment, unsigned char allowOverride, unsigned char valueOp) nogil except? BITMASK_BYTE_CONST
    cdef unsigned char switchTSS16(self) nogil except BITMASK_BYTE_CONST
    cdef unsigned char saveTSS16(self) nogil except BITMASK_BYTE_CONST
    cdef unsigned char switchTSS32(self) nogil except BITMASK_BYTE_CONST
    cdef unsigned char saveTSS32(self) nogil except BITMASK_BYTE_CONST
    cdef void run(self)


