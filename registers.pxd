
include "globals.pxi"
include "cpu_globals.pxi"

from libc.stdint cimport *
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy, memset

from hirnwichse_main cimport Hirnwichse
from mm cimport Mm
from segments cimport Segment, GdtEntry, Gdt, Idt, Paging, Segments

from misc import HirnwichseException

cdef extern from "hirnwichse_eflags.h":
    struct eflagsStruct:
        uint32_t cf
        uint32_t reserved_1
        uint32_t pf
        uint32_t reserved_3
        uint32_t af
        uint32_t reserved_5
        uint32_t zf
        uint32_t sf
        uint32_t tf
        uint32_t if_flag
        uint32_t df
        uint32_t of
        uint32_t iopl
        uint32_t nt
        uint32_t reserved_15
        uint32_t rf
        uint32_t vm
        uint32_t ac
        uint32_t vif
        uint32_t vip
        uint32_t id
        uint32_t reserved_22
        uint32_t reserved_23
        uint32_t reserved_24
        uint32_t reserved_25
        uint32_t reserved_26
        uint32_t reserved_27
        uint32_t reserved_28
        uint32_t reserved_29
        uint32_t reserved_30
        uint32_t reserved_31

cdef:
    struct byteStruct:
        uint8_t rl
        uint8_t rh

    ctypedef union wordUnion:
        byteStruct byte
        uint16_t rx

    struct wordStruct:
        wordUnion _union
        uint16_t notUsed1
        uint32_t notUsed2

    struct dwordStruct:
        uint32_t erx
        uint32_t notUsed1

    ctypedef union qwordUnion:
        uint64_t rrx
        dwordStruct dword
        wordStruct word
        eflagsStruct eflags_struct

    struct RegStruct:
        qwordUnion _union


cdef class ModRMClass:
    cdef Registers registers
    cdef Segment *rmNameSeg
    cdef uint8_t rm, reg, mod, ss, regSize
    cdef uint16_t rmName0, rmName1, regName
    cdef uint64_t rmName2
    cdef uint8_t modRMOperands(self, uint8_t regSize, uint8_t modRMflags) nogil except BITMASK_BYTE_CONST
    cdef uint64_t getRMValueFull(self, uint8_t rmSize) nogil
    cdef int64_t modRMLoadSigned(self, uint8_t regSize) nogil except? BITMASK_BYTE_CONST
    cdef uint64_t modRMLoadUnsigned(self, uint8_t regSize) nogil except? BITMASK_BYTE_CONST
    cdef uint64_t modRMSave(self, uint8_t regSize, uint64_t value, uint8_t valueOp) nogil except? BITMASK_BYTE_CONST # stdValueOp==OPCODE_SAVE
    cdef int64_t modRLoadSigned(self, uint8_t regSize) nogil
    cdef uint64_t modRLoadUnsigned(self, uint8_t regSize) nogil
    cdef uint64_t modRSave(self, uint8_t regSize, uint64_t value, uint8_t valueOp) nogil


cdef class Fpu:
    cdef Hirnwichse main
    cdef Registers registers
    cdef list st
    cdef uint16_t ctrl, status, tag, dataSeg, instSeg, opcode
    cdef uint32_t dataPointer, instPointer
    cdef void reset(self, uint8_t fninit)
    cdef inline uint8_t getPrecision(self)
    cdef inline void setPrecision(self)
    cdef inline void setCtrl(self, uint16_t ctrl)
    cdef inline void setPointers(self, uint16_t opcode)
    cdef inline void setDataPointers(self, uint16_t dataSeg, uint32_t dataPointer)
    cdef inline void setTag(self, uint16_t index, uint8_t tag)
    cdef inline void setFlag(self, uint16_t index, uint8_t flag)
    cdef inline void setExc(self, uint16_t index, uint8_t flag)
    cdef inline void setC(self, uint16_t index, uint8_t flag)
    cdef inline uint8_t getIndex(self, uint8_t index)
    cdef inline void addTop(self, int8_t index)
    cdef inline void setVal(self, uint8_t tempIndex, object data, uint8_t setFlags) # load
    cdef inline object getVal(self, uint8_t tempIndex) # store
    cdef inline void push(self, object data, uint8_t setFlags) # load
    cdef inline object pop(self) # store
    cdef void run(self)


cdef class Registers:
    cdef Hirnwichse main
    cdef Segments segments
    cdef Fpu fpu
    cdef RegStruct regs[CPU_REGISTERS]
    cdef uint8_t cpl, A20Active, protectedModeOn, pagingOn, writeProtectionOn, ssInhibit, cacheDisabled, cpuCacheCodeSegChange, ignoreExceptions
    cdef uint16_t ldtr
    cdef uint32_t cpuCacheBase, cpuCacheSize, cpuCacheIndex
    cdef char *cpuCache
    cpdef quitFunc(self)
    cdef void reset(self) nogil
    cdef inline uint8_t checkCache(self, uint32_t mmAddr, uint8_t dataSize) nogil except BITMASK_BYTE_CONST # called on a memory write; reload cache for self-modifying-code
    cdef inline uint8_t setA20Active(self, uint8_t A20Active) nogil except BITMASK_BYTE_CONST:
        self.A20Active = A20Active
        IF CPU_CACHE_SIZE:
            self.reloadCpuCache()
        return True
    cdef uint8_t reloadCpuCache(self) nogil except BITMASK_BYTE_CONST
    cdef int64_t readFromCacheAddSigned(self, uint8_t numBytes) nogil except? BITMASK_BYTE_CONST
    cdef uint64_t readFromCacheAddUnsigned(self, uint8_t numBytes) nogil except? BITMASK_BYTE_CONST
    cdef uint64_t readFromCacheUnsigned(self, uint8_t numBytes) nogil except? BITMASK_BYTE_CONST
    cdef inline uint32_t readFlags(self) nogil:
        return ((self.regs[CPU_REGISTER_EFLAGS]._union.dword.erx & (~RESERVED_FLAGS_BITMASK)) | FLAG_REQUIRED)
    cdef inline uint8_t setFlags(self, uint32_t flags) nogil
    cdef inline uint8_t getCPL(self) nogil:
        if (not self.protectedModeOn):
            return 0
        elif (self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
            return 3
        return self.cpl
    cdef inline void syncCR0State(self) nogil:
        self.protectedModeOn = self.getFlagDword(CPU_REGISTER_CR0, CR0_FLAG_PE) != 0
    cdef uint8_t getCurrentOpcodeUnsignedByte(self) nogil except? BITMASK_BYTE_CONST
    cdef inline int16_t getCurrentOpcodeAddSignedByte(self) nogil except? BITMASK_BYTE_CONST:
        return <int8_t>self.getCurrentOpcodeAddUnsignedByte()
    cdef inline int16_t getCurrentOpcodeAddSignedWord(self) nogil except? BITMASK_BYTE_CONST:
        return <int16_t>self.getCurrentOpcodeAddUnsignedWord()
    cdef inline int32_t getCurrentOpcodeAddSignedDword(self) nogil except? BITMASK_BYTE_CONST:
        return <int32_t>self.getCurrentOpcodeAddUnsignedDword()
    cdef inline int64_t getCurrentOpcodeAddSignedQword(self) nogil except? BITMASK_BYTE_CONST:
        return <int64_t>self.getCurrentOpcodeAddUnsignedQword()
    cdef int64_t getCurrentOpcodeAddSigned(self, uint8_t numBytes) nogil except? BITMASK_BYTE_CONST
    cdef uint8_t getCurrentOpcodeAddUnsignedByte(self) nogil except? BITMASK_BYTE_CONST
    cdef uint16_t getCurrentOpcodeAddUnsignedWord(self) nogil except? BITMASK_BYTE_CONST
    cdef uint32_t getCurrentOpcodeAddUnsignedDword(self) nogil except? BITMASK_BYTE_CONST
    cdef uint64_t getCurrentOpcodeAddUnsignedQword(self) nogil except? BITMASK_BYTE_CONST
    cdef uint64_t getCurrentOpcodeAddUnsigned(self, uint8_t numBytes) nogil except? BITMASK_BYTE_CONST
    cdef inline uint16_t segRead(self, uint16_t segId) nogil:
        return self.regs[CPU_SEGMENT_BASE+segId]._union.word._union.rx
    cdef uint8_t segWrite(self, uint16_t segId, uint16_t segValue) nogil except BITMASK_BYTE_CONST
    cdef uint8_t segWriteSegment(self, Segment *segment, uint16_t segValue) nogil except BITMASK_BYTE_CONST
    cdef inline int8_t regReadSignedLowByte(self, uint16_t regId) nogil:
        return <int8_t>self.regs[regId]._union.word._union.byte.rl
    cdef inline int8_t regReadSignedHighByte(self, uint16_t regId) nogil:
        return <int8_t>self.regs[regId]._union.word._union.byte.rh
    cdef inline int16_t regReadSignedWord(self, uint16_t regId) nogil:
        return <int16_t>self.regs[regId]._union.word._union.rx
    cdef inline int32_t regReadSignedDword(self, uint16_t regId) nogil:
        return <int32_t>self.regs[regId]._union.dword.erx
    cdef inline int64_t regReadSignedQword(self, uint16_t regId) nogil:
        return <int64_t>self.regs[regId]._union.rrx
    cdef inline uint8_t regReadUnsignedLowByte(self, uint16_t regId) nogil:
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline uint8_t regReadUnsignedHighByte(self, uint16_t regId) nogil:
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline uint16_t regReadUnsignedWord(self, uint16_t regId) nogil:
        return self.regs[regId]._union.word._union.rx
    cdef inline uint32_t regReadUnsignedDword(self, uint16_t regId) nogil:
        return self.regs[regId]._union.dword.erx
    cdef inline uint64_t regReadUnsignedQword(self, uint16_t regId) nogil:
        return self.regs[regId]._union.rrx
    cdef inline uint8_t regWriteLowByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rl = value
        return value # returned value is unsigned!!
    cdef inline uint8_t regWriteHighByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rh = value
        return value # returned value is unsigned!!
    cdef uint16_t regWriteWord(self, uint16_t regId, uint16_t value) nogil except? BITMASK_BYTE_CONST
    cdef uint32_t regWriteDword(self, uint16_t regId, uint32_t value) nogil except? BITMASK_BYTE_CONST
    cdef inline uint64_t regWriteQword(self, uint16_t regId, uint64_t value) nogil:
        IF 0:
        #if (regId == CPU_REGISTER_RFLAGS):
            self.setFlags(<uint32_t>value)
        #else:
        #ELSE:
        self.regs[regId]._union.rrx = value
        return value
    cdef int64_t regReadSigned(self, uint16_t regId, uint8_t regSize) nogil
    cdef uint64_t regReadUnsigned(self, uint16_t regId, uint8_t regSize) nogil
    cdef void regWrite(self, uint16_t regId, uint64_t value, uint8_t regSize) nogil
    cdef inline uint8_t regAddLowByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rl += value
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline uint8_t regAddHighByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rh += value
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline uint16_t regAddWord(self, uint16_t regId, uint16_t value) nogil:
        self.regs[regId]._union.word._union.rx += value
        return self.regs[regId]._union.word._union.rx
    cdef inline uint32_t regAddDword(self, uint16_t regId, uint32_t value) nogil:
        self.regs[regId]._union.dword.erx += value
        return self.regs[regId]._union.dword.erx
    cdef inline uint64_t regAddQword(self, uint16_t regId, uint64_t value) nogil:
        self.regs[regId]._union.rrx += value
        return self.regs[regId]._union.rrx
    cdef inline uint64_t regAdd(self, uint16_t regId, uint64_t value, uint8_t regSize) nogil
    cdef inline uint8_t regAdcLowByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rl += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline uint8_t regAdcHighByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rh += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline uint16_t regAdcWord(self, uint16_t regId, uint16_t value) nogil:
        self.regs[regId]._union.word._union.rx += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.word._union.rx
    cdef inline uint32_t regAdcDword(self, uint16_t regId, uint32_t value) nogil:
        self.regs[regId]._union.dword.erx += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.dword.erx
    cdef inline uint64_t regAdcQword(self, uint16_t regId, uint64_t value) nogil:
        self.regs[regId]._union.rrx += value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.rrx
    cdef inline uint8_t regSubLowByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rl -= value
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline uint8_t regSubHighByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rh -= value
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline uint16_t regSubWord(self, uint16_t regId, uint16_t value) nogil:
        self.regs[regId]._union.word._union.rx -= value
        return self.regs[regId]._union.word._union.rx
    cdef inline uint32_t regSubDword(self, uint16_t regId, uint32_t value) nogil:
        self.regs[regId]._union.dword.erx -= value
        return self.regs[regId]._union.dword.erx
    cdef inline uint64_t regSubQword(self, uint16_t regId, uint64_t value) nogil:
        self.regs[regId]._union.rrx -= value
        return self.regs[regId]._union.rrx
    cdef inline uint64_t regSub(self, uint16_t regId, uint64_t value, uint8_t regSize) nogil
    cdef inline uint8_t regSbbLowByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rl -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline uint8_t regSbbHighByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rh -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline uint16_t regSbbWord(self, uint16_t regId, uint16_t value) nogil:
        self.regs[regId]._union.word._union.rx -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.word._union.rx
    cdef inline uint32_t regSbbDword(self, uint16_t regId, uint32_t value) nogil:
        self.regs[regId]._union.dword.erx -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.dword.erx
    cdef inline uint64_t regSbbQword(self, uint16_t regId, uint64_t value) nogil:
        self.regs[regId]._union.rrx -= value+self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        return self.regs[regId]._union.rrx
    cdef inline uint8_t regXorLowByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rl ^= value
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline uint8_t regXorHighByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rh ^= value
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline uint16_t regXorWord(self, uint16_t regId, uint16_t value) nogil:
        self.regs[regId]._union.word._union.rx ^= value
        return self.regs[regId]._union.word._union.rx
    cdef inline uint32_t regXorDword(self, uint16_t regId, uint32_t value) nogil:
        self.regs[regId]._union.dword.erx ^= value
        return self.regs[regId]._union.dword.erx
    cdef inline uint64_t regXorQword(self, uint16_t regId, uint64_t value) nogil:
        self.regs[regId]._union.rrx ^= value
        return self.regs[regId]._union.rrx
    cdef inline uint8_t regAndLowByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rl &= value
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline uint8_t regAndHighByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rh &= value
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline uint16_t regAndWord(self, uint16_t regId, uint16_t value) nogil:
        self.regs[regId]._union.word._union.rx &= value
        return self.regs[regId]._union.word._union.rx
    cdef inline uint32_t regAndDword(self, uint16_t regId, uint32_t value) nogil:
        self.regs[regId]._union.dword.erx &= value
        return self.regs[regId]._union.dword.erx
    cdef inline uint64_t regAndQword(self, uint16_t regId, uint64_t value) nogil:
        self.regs[regId]._union.rrx &= value
        return self.regs[regId]._union.rrx
    cdef inline uint8_t regOrLowByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rl |= value
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline uint8_t regOrHighByte(self, uint16_t regId, uint8_t value) nogil:
        self.regs[regId]._union.word._union.byte.rh |= value
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline uint16_t regOrWord(self, uint16_t regId, uint16_t value) nogil:
        self.regs[regId]._union.word._union.rx |= value
        return self.regs[regId]._union.word._union.rx
    cdef inline uint32_t regOrDword(self, uint16_t regId, uint32_t value) nogil:
        self.regs[regId]._union.dword.erx |= value
        return self.regs[regId]._union.dword.erx
    cdef inline uint64_t regOrQword(self, uint16_t regId, uint64_t value) nogil:
        self.regs[regId]._union.rrx |= value
        return self.regs[regId]._union.rrx
    cdef inline uint8_t regNegLowByte(self, uint16_t regId) nogil:
        self.regs[regId]._union.word._union.byte.rl = -(self.regs[regId]._union.word._union.byte.rl)
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline uint8_t regNegHighByte(self, uint16_t regId) nogil:
        self.regs[regId]._union.word._union.byte.rh = -(self.regs[regId]._union.word._union.byte.rh)
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline uint16_t regNegWord(self, uint16_t regId) nogil:
        self.regs[regId]._union.word._union.rx = -(self.regs[regId]._union.word._union.rx)
        return self.regs[regId]._union.word._union.rx
    cdef inline uint32_t regNegDword(self, uint16_t regId) nogil:
        self.regs[regId]._union.dword.erx = -(self.regs[regId]._union.dword.erx)
        return self.regs[regId]._union.dword.erx
    cdef inline uint64_t regNegQword(self, uint16_t regId) nogil:
        self.regs[regId]._union.rrx = -(self.regs[regId]._union.rrx)
        return self.regs[regId]._union.rrx
    cdef inline uint8_t regNotLowByte(self, uint16_t regId) nogil:
        self.regs[regId]._union.word._union.byte.rl = ~(self.regs[regId]._union.word._union.byte.rl)
        return self.regs[regId]._union.word._union.byte.rl
    cdef inline uint8_t regNotHighByte(self, uint16_t regId) nogil:
        self.regs[regId]._union.word._union.byte.rh = ~(self.regs[regId]._union.word._union.byte.rh)
        return self.regs[regId]._union.word._union.byte.rh
    cdef inline uint16_t regNotWord(self, uint16_t regId) nogil:
        self.regs[regId]._union.word._union.rx = ~(self.regs[regId]._union.word._union.rx)
        return self.regs[regId]._union.word._union.rx
    cdef inline uint32_t regNotDword(self, uint16_t regId) nogil:
        self.regs[regId]._union.dword.erx = ~(self.regs[regId]._union.dword.erx)
        return self.regs[regId]._union.dword.erx
    cdef inline uint64_t regNotQword(self, uint16_t regId) nogil:
        self.regs[regId]._union.rrx = ~(self.regs[regId]._union.rrx)
        return self.regs[regId]._union.rrx
    cdef inline uint8_t regWriteWithOpLowByte(self, uint16_t regId, uint8_t value, uint8_t valueOp) nogil
    cdef inline uint8_t regWriteWithOpHighByte(self, uint16_t regId, uint8_t value, uint8_t valueOp) nogil
    cdef inline uint16_t regWriteWithOpWord(self, uint16_t regId, uint16_t value, uint8_t valueOp) nogil
    cdef inline uint32_t regWriteWithOpDword(self, uint16_t regId, uint32_t value, uint8_t valueOp) nogil
    cdef inline uint64_t regWriteWithOpQword(self, uint16_t regId, uint64_t value, uint8_t valueOp) nogil
    cdef inline void clearEFLAG(self, uint32_t flags) nogil:
        self.regAndDword(CPU_REGISTER_EFLAGS, ~flags)
    cdef inline uint32_t getFlagDword(self, uint16_t regId, uint32_t flags) nogil:
        return (self.regReadUnsignedDword(regId)&flags)
    cdef inline void setSZP(self, uint32_t value, uint8_t regSize) nogil
    cdef inline void setSZP_O(self, uint32_t value, uint8_t regSize) nogil
    cdef inline void setSZP_A(self, uint32_t value, uint8_t regSize) nogil
    cdef inline void setSZP_COA(self, uint32_t value, uint8_t regSize) nogil
    cdef inline uint8_t getRegNameWithFlags(self, uint8_t modRMflags, uint8_t reg, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef inline uint8_t getCond(self, uint8_t index) nogil
    cdef inline void setFullFlags(self, uint64_t reg0, uint64_t reg1, uint8_t regSize, uint8_t method) nogil
    cdef inline uint32_t mmGetRealAddr(self, uint32_t mmAddr, uint32_t dataSize, Segment *segment, uint8_t allowOverride, uint8_t written, uint8_t noAddress) nogil except? BITMASK_BYTE_CONST
    cdef inline int16_t mmReadValueSignedByte(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST:
        return <int8_t>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
    cdef inline int16_t mmReadValueSignedWord(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST:
        return <int16_t>self.mmReadValueUnsignedWord(mmAddr, segment, allowOverride)
    cdef inline int32_t mmReadValueSignedDword(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST:
        return <int32_t>self.mmReadValueUnsignedDword(mmAddr, segment, allowOverride)
    cdef inline int64_t mmReadValueSignedQword(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST:
        return <int64_t>self.mmReadValueUnsignedQword(mmAddr, segment, allowOverride)
    cdef int64_t mmReadValueSigned(self, uint32_t mmAddr, uint8_t dataSize, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST
    cdef inline uint8_t mmReadValueUnsignedByte(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST
    cdef uint16_t mmReadValueUnsignedWord(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST
    cdef uint32_t mmReadValueUnsignedDword(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST
    cdef uint64_t mmReadValueUnsignedQword(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST
    cdef uint64_t mmReadValueUnsigned(self, uint32_t mmAddr, uint8_t dataSize, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST
    cdef uint8_t mmWriteValue(self, uint32_t mmAddr, uint64_t data, uint8_t dataSize, Segment *segment, uint8_t allowOverride) nogil except BITMASK_BYTE_CONST
    cdef uint64_t mmWriteValueWithOp(self, uint32_t mmAddr, uint64_t data, uint8_t dataSize, Segment *segment, uint8_t allowOverride, uint8_t valueOp) nogil except? BITMASK_BYTE_CONST
    cdef uint8_t switchTSS16(self) nogil except BITMASK_BYTE_CONST
    cdef uint8_t saveTSS16(self) nogil except BITMASK_BYTE_CONST
    cdef uint8_t switchTSS32(self) nogil except BITMASK_BYTE_CONST
    cdef uint8_t saveTSS32(self) nogil except BITMASK_BYTE_CONST
    cdef void run(self)


