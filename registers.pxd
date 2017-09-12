
include "globals.pxi"
include "cpu_globals.pxi"

from libc.stdint cimport *
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy, memset

from hirnwichse_main cimport Hirnwichse
from mm cimport Mm
from segments cimport Segment, GdtEntry, Gdt, Idt, Paging, Segments

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

    ctypedef fused uint8_t_uint16_t_uint32_t:
        uint8_t
        uint16_t
        uint32_t

    ctypedef fused uint8_t_uint16_t_uint32_t_uint64_t:
        uint8_t
        uint16_t
        uint32_t
        uint64_t

    ctypedef fused int8_t_int16_t_int32_t_int64_t:
        int8_t
        int16_t
        int32_t
        int64_t

cdef class ModRMClass:
    cdef Registers registers
    cdef Segment *rmNameSeg
    cdef uint8_t rm, reg, mod, ss, regSize
    cdef uint16_t rmName0, rmName1, regName
    cdef uint64_t rmName2
    cdef uint8_t modRMOperands(self, uint8_t regSize, uint8_t modRMflags) except BITMASK_BYTE_CONST
    cdef uint8_t getRegNameWithFlags(self, uint8_t modRMflags, uint8_t reg, uint8_t operSize)
    cdef uint64_t getRMValueFull(self, uint8_t rmSize)
    cdef int64_t modRMLoadSigned(self, uint8_t regSize) except? BITMASK_BYTE_CONST
    cdef uint64_t modRMLoadUnsigned(self, uint8_t regSize) except? BITMASK_BYTE_CONST
    cdef uint8_t modRMSave(self, uint8_t regSize, uint64_t value, uint8_t valueOp) except BITMASK_BYTE_CONST # stdValueOp==OPCODE_SAVE
    cdef int64_t modRLoadSigned(self, uint8_t regSize)
    cdef uint64_t modRLoadUnsigned(self, uint8_t regSize)
    cdef void modRSave(self, uint8_t_uint16_t_uint32_t_uint64_t value, uint8_t valueOp)


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
    cdef uint32_t cpuCacheBase, cpuCacheSize, cpuCacheIndex, apicBase, apicBaseReal, apicBaseRealPlusSize
    cdef char *cpuCache
    cdef void quitFunc(self)
    cdef void reset(self)
    cdef inline uint8_t checkCache(self, uint32_t mmAddr, uint8_t dataSize) except BITMASK_BYTE_CONST # called on a memory write; reload cache for self-modifying-code
    cdef inline uint8_t setA20Active(self, uint8_t A20Active) except BITMASK_BYTE_CONST:
        self.A20Active = A20Active
        IF CPU_CACHE_SIZE:
            self.reloadCpuCache()
        return True
    cdef uint8_t reloadCpuCache(self) except BITMASK_BYTE_CONST
    cdef uint64_t readFromCacheAddUnsigned(self, uint8_t numBytes) except? BITMASK_BYTE_CONST
    cdef uint64_t readFromCacheUnsigned(self, uint8_t numBytes) except? BITMASK_BYTE_CONST
    cdef inline uint32_t readFlags(self):
        return ((self.regs[CPU_REGISTER_EFLAGS]._union.dword.erx & (~RESERVED_FLAGS_BITMASK)) | FLAG_REQUIRED)
    cdef inline uint8_t getCPL(self):
        if (not self.protectedModeOn):
            return 0
        elif (self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
            return 3
        return self.cpl
    cdef inline void syncCR0State(self):
        self.protectedModeOn = self.getFlagDword(CPU_REGISTER_CR0, CR0_FLAG_PE) != 0
    cdef uint8_t getCurrentOpcodeUnsignedByte(self) except? BITMASK_BYTE_CONST
    cdef uint8_t getCurrentOpcodeAddUnsignedByte(self) except? BITMASK_BYTE_CONST
    cdef uint16_t getCurrentOpcodeAddUnsignedWord(self) except? BITMASK_BYTE_CONST
    cdef uint32_t getCurrentOpcodeAddUnsignedDword(self) except? BITMASK_BYTE_CONST
    cdef uint64_t getCurrentOpcodeAddUnsignedQword(self) except? BITMASK_BYTE_CONST
    cdef uint64_t getCurrentOpcodeAddUnsigned(self, uint8_t numBytes) except? BITMASK_BYTE_CONST
    cdef inline uint8_t isAddressInLimit(self, GdtEntry *gdtEntry, uint32_t address, uint32_t size)
    cdef uint8_t segWriteSegment(self, Segment *segment, uint16_t segValue) except BITMASK_BYTE_CONST
    cdef uint8_t regWriteWord(self, uint16_t regId, uint16_t value) except BITMASK_BYTE_CONST
    cdef uint8_t regWriteDword(self, uint16_t regId, uint32_t value) except BITMASK_BYTE_CONST
    cdef uint8_t regWriteQword(self, uint16_t regId, uint64_t value) except BITMASK_BYTE_CONST
    cdef uint64_t regReadUnsigned(self, uint16_t regId, uint8_t regSize)
    cdef void regWrite(self, uint16_t regId, uint64_t value, uint8_t regSize)
    cdef inline void regWriteWithOpLowByte(self, uint16_t regId, uint8_t value, uint8_t valueOp)
    cdef inline void regWriteWithOpHighByte(self, uint16_t regId, uint8_t value, uint8_t valueOp)
    cdef inline void regWriteWithOpWord(self, uint16_t regId, uint16_t value, uint8_t valueOp)
    cdef inline void regWriteWithOpDword(self, uint16_t regId, uint32_t value, uint8_t valueOp)
    cdef inline void regWriteWithOpQword(self, uint16_t regId, uint64_t value, uint8_t valueOp)
    cdef inline uint32_t getFlagDword(self, uint16_t regId, uint32_t flags) nogil:
        return (self.regs[regId]._union.dword.erx&flags)
    cdef void setSZP(self, uint32_t value, uint8_t regSize)
    cdef void setSZP_O(self, uint32_t value, uint8_t regSize)
    cdef void setSZP_A(self, uint32_t value, uint8_t regSize)
    cdef void setSZP_COA(self, uint32_t value, uint8_t regSize)
    cdef inline uint8_t getCond(self, uint8_t index)
    #cdef void setFullFlags_(self, uint64_t reg0, uint64_t reg1, uint8_t regSize, uint8_t method)
    cdef void setFullFlags(self, uint8_t_uint16_t_uint32_t reg0, uint8_t_uint16_t_uint32_t reg1, uint8_t method)
    cdef inline uint32_t mmGetRealAddr(self, uint32_t mmAddr, uint32_t dataSize, Segment *segment, uint8_t allowOverride, uint8_t written, uint8_t noAddress) except? BITMASK_BYTE_CONST
    cdef inline uint8_t mmReadValueUnsignedByte(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) except? BITMASK_BYTE_CONST
    cdef uint16_t mmReadValueUnsignedWord(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) except? BITMASK_BYTE_CONST
    cdef uint32_t mmReadValueUnsignedDword(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) except? BITMASK_BYTE_CONST
    cdef uint64_t mmReadValueUnsignedQword(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) except? BITMASK_BYTE_CONST
    cdef uint64_t mmReadValueUnsigned(self, uint32_t mmAddr, uint8_t dataSize, Segment *segment, uint8_t allowOverride) except? BITMASK_BYTE_CONST
    cdef uint8_t mmWriteValue(self, uint32_t mmAddr, uint64_t data, uint8_t dataSize, Segment *segment, uint8_t allowOverride) except BITMASK_BYTE_CONST
    cdef uint8_t mmWriteValueWithOp(self, uint32_t mmAddr, uint64_t data, uint8_t dataSize, Segment *segment, uint8_t allowOverride, uint8_t valueOp) except BITMASK_BYTE_CONST
    cdef uint8_t switchTSS16(self) except BITMASK_BYTE_CONST
    cdef uint8_t saveTSS16(self) except BITMASK_BYTE_CONST
    cdef uint8_t switchTSS32(self) except BITMASK_BYTE_CONST
    cdef uint8_t saveTSS32(self) except BITMASK_BYTE_CONST
    cdef void run(self)


