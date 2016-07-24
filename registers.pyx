
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"
include "cpu_globals.pxi"

from misc import HirnwichseException
import gmpy2, struct
from traceback import print_exc
from atexit import register

# Parity Flag Table: DO NOT EDIT!!!
cdef uint8_t PARITY_TABLE[256]
PARITY_TABLE = (True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, False, True, True, False,
                True, False, False, True, True, False, False, True, False, True,
                True, False, False, True, True, False, True, False, False, True,
                True, False, False, True, False, True, True, False, True, False,
                False, True, False, True, True, False, False, True, True, False,
                True, False, False, True, False, True, True, False, True, False,
                False, True, True, False, False, True, False, True, True, False,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, True, False, False, True,
                False, True, True, False, False, True, True, False, True, False,
                False, True, False, True, True, False, True, False, False, True,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, True, False, False, True,
                False, True, True, False, True, False, False, True, False, True,
                True, False, False, True, True, False, True, False, False, True,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, False, True, True, False,
                True, False, False, True, True, False, False, True, False, True,
                True, False, True, False, False, True, False, True, True, False,
                False, True, True, False, True, False, False, True, False, True,
                True, False, True, False, False, True, True, False, False, True,
                False, True, True, False, False, True, True, False, True, False,
                False, True, True, False, False, True, False, True, True, False,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True)



cdef class ModRMClass:
    def __init__(self, Registers registers):
        self.registers = registers
    cdef uint8_t modRMOperands(self, uint8_t regSize, uint8_t modRMflags) nogil except BITMASK_BYTE_CONST: # regSize in bytes
        cdef uint8_t modRMByte
        modRMByte = self.registers.getCurrentOpcodeAddUnsignedByte()
        self.rmNameSeg = &self.registers.segments.ds
        self.rmName1 = CPU_REGISTER_NONE
        self.rm  = modRMByte&0x7
        self.reg = (modRMByte>>3)&0x7
        self.mod = (modRMByte>>6)&0x3
        self.ss = 0
        self.regName = self.registers.getRegNameWithFlags(modRMflags, self.reg, regSize) # reg
        if (self.mod == 3): # if mod==3, then: reg is source ; rm is dest
            self.regSize = regSize
            self.rmName0 = self.rm # rm
            if (regSize == OP_SIZE_BYTE):
                self.rmName0 &= 3
            self.rmName2 = 0
        else:
            self.regSize = self.registers.main.cpu.addrSize
            if (self.regSize == OP_SIZE_WORD):
                self.rmName0 = CPU_MODRM_16BIT_RM0[self.rm]
                self.rmName1 = CPU_MODRM_16BIT_RM1[self.rm]
                if (self.mod == 0 and self.rm == 6):
                    self.rmName0 = CPU_REGISTER_NONE
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedWord()
                elif (self.mod == 1):
                    self.rmName2 = <uint16_t>(<int8_t>self.registers.getCurrentOpcodeAddSignedByte())
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedWord()
                else:
                    self.rmName2 = 0
            elif (self.regSize == OP_SIZE_DWORD):
                if (self.rm == 4): # If RM==4; then SIB
                    modRMByte = self.registers.getCurrentOpcodeAddUnsignedByte()
                    self.rm  = modRMByte&0x7
                    self.ss = (modRMByte>>6)&3
                    modRMByte   = (modRMByte>>3)&7
                    if (modRMByte != 4):
                        self.rmName1 = modRMByte
                self.rmName0 = self.rm
                if (self.mod == 0 and self.rm == 5):
                    self.rmName0 = CPU_REGISTER_NONE
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedDword()
                elif (self.mod == 1):
                    self.rmName2 = <uint32_t>(<int8_t>self.registers.getCurrentOpcodeAddSignedByte())
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedDword()
                else:
                    self.rmName2 = 0
            if (self.rmName0 in (CPU_REGISTER_ESP, CPU_REGISTER_EBP)): # on 16-bit modrm, there's no SP
                self.rmNameSeg = &self.registers.segments.ss
        return True
    cdef uint64_t getRMValueFull(self, uint8_t rmSize) nogil:
        cdef uint64_t retAddr = 0
        if (self.rmName0 != CPU_REGISTER_NONE):
            if (self.regSize in (OP_SIZE_BYTE, OP_SIZE_WORD)):
                retAddr = self.registers.regReadUnsignedWord(self.rmName0)
                if (self.regSize == OP_SIZE_BYTE):
                    if (self.rm >= 4):
                        retAddr >>= 8
                    retAddr = <uint8_t>retAddr
            elif (self.regSize == OP_SIZE_DWORD):
                retAddr = self.registers.regReadUnsignedDword(self.rmName0)
            elif (self.regSize == OP_SIZE_QWORD):
                retAddr = self.registers.regReadUnsignedQword(self.rmName0)
        if (self.rmName1 != CPU_REGISTER_NONE):
            retAddr += self.registers.regReadUnsigned(self.rmName1, self.regSize)<<self.ss
        retAddr += self.rmName2
        if (rmSize == OP_SIZE_BYTE):
            return <uint8_t>retAddr
        elif (rmSize == OP_SIZE_WORD):
            return <uint16_t>retAddr
        elif (rmSize == OP_SIZE_DWORD):
            return <uint32_t>retAddr
        return retAddr
    cdef int64_t modRMLoadSigned(self, uint8_t regSize) nogil except? BITMASK_BYTE_CONST:
        # NOTE: imm == unsigned ; disp == signed
        cdef uint64_t mmAddr
        cdef int64_t returnInt
        if (self.mod == 3):
            if (regSize == OP_SIZE_BYTE):
                if (self.rm <= 3):
                    returnInt = self.registers.regReadSignedLowByte(self.rmName0)
                else: #elif (self.rm >= 4):
                    returnInt = self.registers.regReadSignedHighByte(self.rmName0)
            elif (regSize == OP_SIZE_WORD):
                returnInt = self.registers.regReadSignedWord(self.rmName0)
            elif (regSize == OP_SIZE_DWORD):
                returnInt = self.registers.regReadSignedDword(self.rmName0)
            elif (regSize == OP_SIZE_QWORD):
                returnInt = self.registers.regReadSignedQword(self.rmName0)
        else:
            mmAddr = self.getRMValueFull(self.regSize)
            returnInt = self.registers.mmReadValueSigned(mmAddr, regSize, self.rmNameSeg, True)
        return returnInt
    cdef uint64_t modRMLoadUnsigned(self, uint8_t regSize) nogil except? BITMASK_BYTE_CONST:
        # NOTE: imm == unsigned ; disp == signed
        cdef uint64_t mmAddr, returnInt # = 0
        if (self.mod == 3):
            if (regSize == OP_SIZE_BYTE):
                if (self.rm <= 3):
                    returnInt = self.registers.regReadUnsignedLowByte(self.rmName0)
                else: #elif (self.rm >= 4):
                    returnInt = self.registers.regReadUnsignedHighByte(self.rmName0)
            elif (regSize == OP_SIZE_WORD):
                returnInt = self.registers.regReadUnsignedWord(self.rmName0)
            elif (regSize == OP_SIZE_DWORD):
                returnInt = self.registers.regReadUnsignedDword(self.rmName0)
            elif (regSize == OP_SIZE_QWORD):
                returnInt = self.registers.regReadUnsignedQword(self.rmName0)
        else:
            mmAddr = self.getRMValueFull(self.regSize)
            returnInt = self.registers.mmReadValueUnsigned(mmAddr, regSize, self.rmNameSeg, True)
        return returnInt
    cdef uint64_t modRMSave(self, uint8_t regSize, uint64_t value, uint8_t valueOp) nogil except? BITMASK_BYTE_CONST:
        # stdValueOp==OPCODE_SAVE
        cdef uint64_t mmAddr
        if (self.mod != 3):
            mmAddr = self.getRMValueFull(self.regSize)
        if (regSize == OP_SIZE_BYTE):
            value = <uint8_t>value
            if (self.mod == 3):
                if (self.rm <= 3):
                    return self.registers.regWriteWithOpLowByte(self.rmName0, value, valueOp)
                #else: # self.rm >= 4
                return self.registers.regWriteWithOpHighByte(self.rmName0, value, valueOp)
            return <uint8_t>self.registers.mmWriteValueWithOp(mmAddr, value, regSize, self.rmNameSeg, True, valueOp)
        elif (regSize == OP_SIZE_WORD):
            value = <uint16_t>value
            if (self.mod == 3):
                return self.registers.regWriteWithOpWord(self.rmName0, value, valueOp)
            return <uint16_t>self.registers.mmWriteValueWithOp(mmAddr, value, regSize, self.rmNameSeg, True, valueOp)
        elif (regSize == OP_SIZE_DWORD):
            value = <uint32_t>value
            if (self.mod == 3):
                return self.registers.regWriteWithOpDword(self.rmName0, value, valueOp)
            return <uint32_t>self.registers.mmWriteValueWithOp(mmAddr, value, regSize, self.rmNameSeg, True, valueOp)
        elif (regSize == OP_SIZE_QWORD):
            if (self.mod == 3):
                return self.registers.regWriteWithOpQword(self.rmName0, value, valueOp)
            return self.registers.mmWriteValueWithOp(mmAddr, value, regSize, self.rmNameSeg, True, valueOp)
        #self.registers.main.exitError("ModRMClass::modRMSave: if; else.")
        return 0
    cdef int64_t modRLoadSigned(self, uint8_t regSize) nogil:
        cdef int64_t retVal # = 0
        if (regSize == OP_SIZE_BYTE):
            if (self.reg <= 3):
                retVal = self.registers.regReadSignedLowByte(self.regName)
            else: #elif (self.reg >= 4):
                retVal = self.registers.regReadSignedHighByte(self.regName)
        elif (regSize == OP_SIZE_WORD):
            retVal = self.registers.regReadSignedWord(self.regName)
        elif (regSize == OP_SIZE_DWORD):
            retVal = self.registers.regReadSignedDword(self.regName)
        elif (regSize == OP_SIZE_QWORD):
            retVal = self.registers.regReadSignedQword(self.regName)
        return retVal
    cdef uint64_t modRLoadUnsigned(self, uint8_t regSize) nogil:
        cdef uint64_t retVal # = 0
        if (regSize == OP_SIZE_BYTE):
            if (self.reg <= 3):
                retVal = self.registers.regReadUnsignedLowByte(self.regName)
            else: #elif (self.reg >= 4):
                retVal = self.registers.regReadUnsignedHighByte(self.regName)
        elif (regSize == OP_SIZE_WORD):
            retVal = self.registers.regReadUnsignedWord(self.regName)
        elif (regSize == OP_SIZE_DWORD):
            retVal = self.registers.regReadUnsignedDword(self.regName)
        elif (regSize == OP_SIZE_QWORD):
            retVal = self.registers.regReadUnsignedQword(self.regName)
        return retVal
    cdef uint64_t modRSave(self, uint8_t regSize, uint64_t value, uint8_t valueOp) nogil:
        if (regSize == OP_SIZE_BYTE):
            value = <uint8_t>value
            if (self.reg <= 3):
                return self.registers.regWriteWithOpLowByte(self.regName, value, valueOp)
            #else: #elif (self.reg >= 4):
            return self.registers.regWriteWithOpHighByte(self.regName, value, valueOp)
        elif (regSize == OP_SIZE_WORD):
            value = <uint16_t>value
            return self.registers.regWriteWithOpWord(self.regName, value, valueOp)
        elif (regSize == OP_SIZE_DWORD):
            value = <uint32_t>value
            return self.registers.regWriteWithOpDword(self.regName, value, valueOp)
        elif (regSize == OP_SIZE_QWORD):
            return self.registers.regWriteWithOpQword(self.regName, value, valueOp)


cdef class Fpu:
    def __init__(self, Registers registers, Hirnwichse main):
        self.registers = registers
        self.main = main
        self.st = [None]*8
        #self.opcode = 0
    cdef void reset(self, uint8_t fninit):
        cdef uint8_t i
        if (fninit):
            self.setCtrl(0x37f)
            self.tag = 0xffff
        else:
            for i in range(8):
                self.st[i] = bytes(10)
            self.setCtrl(0x40)
            self.tag = 0x5555
        self.status = 0
        self.dataSeg = self.instSeg = 0
        self.dataPointer = self.instPointer = 0
        self.opcode = 0 # TODO: should this get cleared?
    cdef inline uint8_t getPrecision(self):
        return FPU_PRECISION[(self.ctrl>>8)&3]
    cdef inline void setPrecision(self):
        gmpy2.get_context().precision=self.getPrecision()
    cdef inline void setCtrl(self, uint16_t ctrl):
        self.ctrl = ctrl
        self.setPrecision()
    cdef inline void setPointers(self, uint16_t opcode):
        self.opcode = opcode
        self.instSeg = self.main.cpu.savedCs
        self.instPointer = self.main.cpu.savedEip
    cdef inline void setDataPointers(self, uint16_t dataSeg, uint32_t dataPointer):
        self.dataSeg = dataSeg
        self.dataPointer = dataPointer
    cdef inline void setTag(self, uint16_t index, uint8_t tag):
        index <<= 1
        self.tag &= ~(3<<index)
        self.tag |= tag<<index
    cdef inline void setFlag(self, uint16_t index, uint8_t flag):
        index = 1<<index
        if (flag):
            self.status |= index
        else:
            self.status &= ~index
    cdef inline void setExc(self, uint16_t index, uint8_t flag):
        self.setFlag(index, flag)
        index = 1<<index
        if (flag and (self.ctrl & index) != 0):
            self.setFlag(FPU_EXCEPTION_ES, True)
    cdef inline void setC(self, uint16_t index, uint8_t flag):
        if (index < 3):
            index = 8+index
        else:
            index = 14
        self.setFlag(index, flag)
    cdef inline uint8_t getIndex(self, uint8_t index):
        return (((self.status >> 11) & 7) + index) & 7
    cdef inline void addTop(self, int8_t index):
        cdef char tempIndex
        tempIndex = (self.status >> 11) & 7
        self.status &= ~(7 << 11)
        tempIndex += index
        self.status |= (tempIndex & 7) << 11
    cdef inline void setVal(self, uint8_t tempIndex, object data, uint8_t setFlags): # load
        cdef int32_t tempVal
        cdef tuple tempTuple
        cdef bytes tempData
        data = gmpy2.mpfr(data)
        self.main.notice("Fpu::setVal: data=={0:s}", repr(data))
        tempIndex = self.getIndex(tempIndex)
        if (not gmpy2.is_zero(data)):
            tempTuple = data.as_integer_ratio()
            tempVal = (tempTuple[0].bit_length()-tempTuple[1].bit_length())
            tempVal = <uint16_t>(tempVal+16383)
            if (gmpy2.is_signed(data)):
                tempVal |= 0x8000
            tempData = (gmpy2.to_binary(data))[:11:-1]
            self.st[tempIndex] = tempVal.to_bytes(OP_SIZE_WORD, byteorder="big")+tempData
        else:
            self.st[tempIndex] = bytes(10)
        self.main.notice("Fpu::setVal: tempIndex=={0:d}, len(st[ti])=={1:d}, repr(st[ti]=={2:s})", tempIndex, len(self.st[tempIndex]), repr(self.st[tempIndex]))
        if (gmpy2.is_zero(data)):
            self.setTag(tempIndex, 1)
        elif (not gmpy2.is_regular(data)):
            self.setTag(tempIndex, 2)
        else:
            self.setTag(tempIndex, 0)
        if (setFlags):
            if (data.rc != 0):
                self.setExc(FPU_EXCEPTION_PE, True)
            self.setC(1, data.rc > 0)
    cdef inline object getVal(self, uint8_t tempIndex): # store
        cdef uint8_t negative, info_byte
        cdef uint32_t exp
        cdef object data
        tempIndex = self.getIndex(tempIndex)
        self.main.notice("Fpu::getVal: tempIndex=={0:d}, len(st[ti])=={1:d}, repr(st[ti]=={2:s})", tempIndex, len(self.st[tempIndex]), repr(self.st[tempIndex]))
        if (self.st[tempIndex] == bytes(10)):
            return gmpy2.mpfr(0)
        exp = int.from_bytes(self.st[tempIndex][:2],byteorder="big")
        negative = (exp & 0x8000) != 0
        exp &= <uint16_t>(~(<uint16_t>0x8000))
        exp = <uint16_t>((exp-16383)+1)
        if (negative):
            info_byte = 0x43
        else:
            info_byte = 0x41
        if (exp >= 0x8000):
            exp = 0x10000 - exp
            info_byte |= 0x20
        data = gmpy2.from_binary(b"\x04"+bytes([ info_byte ])+b"\x00\x00"+bytes([self.getPrecision()])+b"\x00\x00\x00"+struct.pack("<I", exp)+self.st[tempIndex][9:1:-1])
        self.main.notice("Fpu::getVal: data=={0:s}", repr(data))
        return data
    cdef inline void push(self, object data, uint8_t setFlags): # load
        self.addTop(-1)
        self.setVal(0, data, setFlags)
    cdef inline object pop(self): # store
        cdef object data
        data = self.getVal(0)
        self.setTag(self.getIndex(0), 3)
        self.addTop(1)
        return data
    cdef void run(self):
        pass


cdef class Registers:
    def __init__(self, Hirnwichse main):
        self.main = main
        self.segments = Segments(self, self.main)
        self.fpu = Fpu(self, self.main)
        IF CPU_CACHE_SIZE:
            with nogil:
                self.cpuCache = <char*>malloc(CPU_CACHE_SIZE<<1)
            if (self.cpuCache is NULL):
                self.main.exitError("Registers::init: not self.cpuCache.")
                return
            with nogil:
                memset(self.cpuCache, 0, CPU_CACHE_SIZE<<1)
        self.regWriteDword(CPU_REGISTER_CR0, CR0_FLAG_CD | CR0_FLAG_NW | CR0_FLAG_ET)
        register(self.quitFunc)
    cpdef quitFunc(self):
        try:
            self.main.quitFunc()
            IF CPU_CACHE_SIZE:
                if (self.cpuCache is not NULL):
                    with nogil:
                        free(self.cpuCache)
                    self.cpuCache = NULL
        except:
            print_exc()
            self.main.exitError('Registers::quitFunc: exception, exiting...')
    cdef void reset(self) nogil:
        self.cpl = self.protectedModeOn = self.pagingOn = self.writeProtectionOn = self.ssInhibit = self.cacheDisabled = self.cpuCacheBase = self.cpuCacheSize = self.cpuCacheIndex = self.ldtr = self.cpuCacheCodeSegChange = self.ignoreExceptions = 0
        self.A20Active = True
        IF CPU_CACHE_SIZE:
            with nogil:
                memset(self.cpuCache, 0, CPU_CACHE_SIZE<<1)
        with gil:
            self.fpu.reset(False)
        self.regWriteDword(CPU_REGISTER_EFLAGS, FLAG_REQUIRED)
        self.regWriteDword(CPU_REGISTER_CR0, self.getFlagDword(CPU_REGISTER_CR0, CR0_FLAG_CD | CR0_FLAG_NW) | CR0_FLAG_ET)
        #self.regWriteDword(CPU_REGISTER_DR6, 0xffff1ff0) # why has bochs bit 12 set?
        self.regWriteDword(CPU_REGISTER_DR6, 0xffff0ff0)
        self.regWriteDword(CPU_REGISTER_DR7, 0x400)
        #self.regWriteDword(CPU_REGISTER_EDX, 0x521)
        #self.regWriteDword(CPU_REGISTER_EDX, 0x611)
        #self.regWriteDword(CPU_REGISTER_EDX, 0x631)
        self.regWriteDword(CPU_REGISTER_EDX, 0x635)
        self.segWriteSegment(&self.segments.cs, 0xf000)
        self.regWriteDword(CPU_REGISTER_EIP, 0xfff0)
    cdef inline uint8_t checkCache(self, uint32_t mmAddr, uint8_t dataSize) nogil except BITMASK_BYTE_CONST: # called on a memory write; reload cache for self-modifying-code
        cdef uint32_t cpuCacheBasePhy
        IF CPU_CACHE_SIZE:
            self.ignoreExceptions = True
            cpuCacheBasePhy = self.mmGetRealAddr(self.cpuCacheBase, 1, NULL, False, False, False)
            if (not self.ignoreExceptions):
                self.reloadCpuCache()
                return True
            else:
                self.ignoreExceptions = False
            if (self.cpuCacheCodeSegChange or (mmAddr >= cpuCacheBasePhy and mmAddr+dataSize <= cpuCacheBasePhy+self.cpuCacheSize)):
                self.reloadCpuCache()
        return True
    cdef uint8_t reloadCpuCache(self) nogil except BITMASK_BYTE_CONST:
        IF CPU_CACHE_SIZE:
            cdef uint32_t mmAddr, mmAddr2, temp, offset=0, tempSize=0
            cdef char *tempMmArea
            IF COMP_DEBUG:
                if (self.main.debugEnabled):
                    with gil:
                        self.main.notice("Registers::reloadCpuCache: EIP: {0:#010x}", self.regs[CPU_REGISTER_EIP]._union.dword.erx)
            mmAddr = self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, 1, &self.segments.cs, False, False, False)
            if (self.protectedModeOn and self.pagingOn):
                while (offset < CPU_CACHE_SIZE):
                    temp = SIZE_4KB-((self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx+offset)&0xfff)
                    self.ignoreExceptions = True
                    mmAddr2 = self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx+offset, temp, &self.segments.cs, False, False, False)
                    if (not self.ignoreExceptions):
                        break
                    else:
                        self.ignoreExceptions = False
                    tempMmArea = self.main.mm.mmPhyRead(mmAddr2, temp)
                    with nogil:
                        memcpy(self.cpuCache+offset, tempMmArea, temp)
                    offset += temp
                    tempSize += temp
            else:
                tempMmArea = self.main.mm.mmPhyRead(mmAddr, CPU_CACHE_SIZE)
                with nogil:
                    memcpy(self.cpuCache, tempMmArea, CPU_CACHE_SIZE)
                tempSize = CPU_CACHE_SIZE
            self.cpuCacheBase = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.cpuCacheSize = tempSize
            self.cpuCacheIndex = self.cpuCacheCodeSegChange = 0
        return True
    cdef int64_t readFromCacheAddSigned(self, uint8_t numBytes) nogil except? BITMASK_BYTE_CONST:
        IF CPU_CACHE_SIZE:
            cdef int64_t *retVal
            if (self.cpuCacheIndex+numBytes > self.cpuCacheSize):
                self.reloadCpuCache()
            retVal = <int64_t*>(self.cpuCache+self.cpuCacheIndex)
            self.cpuCacheIndex += numBytes
            if (numBytes == OP_SIZE_BYTE):
                return <int8_t>retVal[0]
            elif (numBytes == OP_SIZE_WORD):
                return <int16_t>retVal[0]
            elif (numBytes == OP_SIZE_DWORD):
                return <int32_t>retVal[0]
            #else:
            return retVal[0]
        ELSE:
            return 0
    cdef uint64_t readFromCacheAddUnsigned(self, uint8_t numBytes) nogil except? BITMASK_BYTE_CONST:
        IF CPU_CACHE_SIZE:
            cdef uint64_t *retVal
            IF COMP_DEBUG:
                with gil:
                    if (self.main.debugEnabled):
                        self.main.notice("Registers::readFromCacheAddUnsigned: cpuCacheIndex: {0:#010x}, numBytes: {1:d}", self.cpuCacheIndex, numBytes)
            if (self.cpuCacheIndex+numBytes > self.cpuCacheSize):
                self.reloadCpuCache()
            retVal = <uint64_t*>(self.cpuCache+self.cpuCacheIndex)
            self.cpuCacheIndex += numBytes
            if (numBytes == OP_SIZE_BYTE):
                return <uint8_t>retVal[0]
            elif (numBytes == OP_SIZE_WORD):
                return <uint16_t>retVal[0]
            elif (numBytes == OP_SIZE_DWORD):
                return <uint32_t>retVal[0]
            #else:
            return retVal[0]
        ELSE:
            return 0
    cdef uint64_t readFromCacheUnsigned(self, uint8_t numBytes) nogil except? BITMASK_BYTE_CONST:
        IF CPU_CACHE_SIZE:
            cdef uint64_t *retVal
            if (self.cpuCacheIndex+numBytes > self.cpuCacheSize):
                self.reloadCpuCache()
            retVal = <uint64_t*>(self.cpuCache+self.cpuCacheIndex)
            if (numBytes == OP_SIZE_BYTE):
                return <uint8_t>retVal[0]
            elif (numBytes == OP_SIZE_WORD):
                return <uint16_t>retVal[0]
            elif (numBytes == OP_SIZE_DWORD):
                return <uint32_t>retVal[0]
            #else:
            return retVal[0]
        ELSE:
            return 0
    cdef inline uint8_t setFlags(self, uint32_t flags) nogil:
        cdef uint8_t ifEnabled
        ifEnabled = ((not self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.if_flag) and ((flags>>9)&1))
        if (ifEnabled):
            self.main.cpu.asyncEvent = True
        return True
    cdef uint8_t getCurrentOpcodeUnsignedByte(self) nogil except? BITMASK_BYTE_CONST:
        cdef uint8_t ret
        cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueUnsignedByte(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_BYTE, &self.segments.cs, False, False, True)
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_BYTE):
                    self.reloadCpuCache()
                ret = <uint8_t>self.readFromCacheUnsigned(OP_SIZE_BYTE)
        ELSE:
            ret = self.mmReadValueUnsignedByte(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
        IF COMP_DEBUG:
            with gil:
                if (self.main.debugEnabled):
                    self.main.notice("Registers::getCurrentOpcodeUnsignedByte: EIP: {0:#010x}, ret=={1:#04x}", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        return ret
    cdef int64_t getCurrentOpcodeAddSigned(self, uint8_t numBytes) nogil except? BITMASK_BYTE_CONST:
        cdef int64_t ret
        cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueSigned(self.regs[CPU_REGISTER_EIP]._union.dword.erx, numBytes, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, numBytes, &self.segments.cs, False, False, True)
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < numBytes):
                    self.reloadCpuCache()
                ret = self.readFromCacheAddSigned(numBytes)
        ELSE:
            ret = self.mmReadValueSigned(self.regs[CPU_REGISTER_EIP]._union.dword.erx, numBytes, &self.segments.cs, False)
        IF COMP_DEBUG:
            with gil:
                if (self.main.debugEnabled):
                    self.main.notice("Registers::getCurrentOpcodeAddSigned: EIP: {0:#010x}, ret=={1:#04x}", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        self.regs[CPU_REGISTER_EIP]._union.dword.erx += numBytes
        return ret
    cdef uint8_t getCurrentOpcodeAddUnsignedByte(self) nogil except? BITMASK_BYTE_CONST:
        cdef uint8_t ret
        cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueUnsignedByte(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_BYTE, &self.segments.cs, False, False, True)
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_BYTE):
                    self.reloadCpuCache()
                ret = <uint8_t>self.readFromCacheAddUnsigned(OP_SIZE_BYTE)
        ELSE:
            ret = self.mmReadValueUnsignedByte(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
        IF COMP_DEBUG:
            with gil:
                if (self.main.debugEnabled):
                    self.main.notice("Registers::getCurrentOpcodeAddUnsignedByte: EIP: {0:#010x}, ret=={1:#04x}", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_BYTE
        return ret
    cdef uint16_t getCurrentOpcodeAddUnsignedWord(self) nogil except? BITMASK_BYTE_CONST:
        cdef uint16_t ret
        cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueUnsignedWord(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_WORD, &self.segments.cs, False, False, True)
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_WORD):
                    self.reloadCpuCache()
                ret = <uint16_t>self.readFromCacheAddUnsigned(OP_SIZE_WORD)
        ELSE:
            ret = self.mmReadValueUnsignedWord(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
        IF COMP_DEBUG:
            with gil:
                if (self.main.debugEnabled):
                    self.main.notice("Registers::getCurrentOpcodeAddUnsignedWord: EIP: {0:#010x}, ret=={1:#04x}", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_WORD
        return ret
    cdef uint32_t getCurrentOpcodeAddUnsignedDword(self) nogil except? BITMASK_BYTE_CONST:
        cdef uint32_t ret
        cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueUnsignedDword(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_DWORD, &self.segments.cs, False, False, True)
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_DWORD):
                    self.reloadCpuCache()
                ret = <uint32_t>self.readFromCacheAddUnsigned(OP_SIZE_DWORD)
        ELSE:
            ret = self.mmReadValueUnsignedDword(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
        IF COMP_DEBUG:
            with gil:
                if (self.main.debugEnabled):
                    self.main.notice("Registers::getCurrentOpcodeAddUnsignedDword: EIP: {0:#010x}, ret=={1:#04x}", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_DWORD
        return ret
    cdef uint64_t getCurrentOpcodeAddUnsignedQword(self) nogil except? BITMASK_BYTE_CONST:
        cdef uint64_t ret
        cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueUnsignedQword(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_QWORD, &self.segments.cs, False, False, True)
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_QWORD):
                    self.reloadCpuCache()
                ret = self.readFromCacheAddUnsigned(OP_SIZE_QWORD)
        ELSE:
            ret = self.mmReadValueUnsignedQword(self.regs[CPU_REGISTER_EIP]._union.dword.erx, &self.segments.cs, False)
        IF COMP_DEBUG:
            with gil:
                if (self.main.debugEnabled):
                    self.main.notice("Registers::getCurrentOpcodeAddUnsignedQword: EIP: {0:#010x}, ret=={1:#04x}", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_QWORD
        return ret
    cdef uint64_t getCurrentOpcodeAddUnsigned(self, uint8_t numBytes) nogil except? BITMASK_BYTE_CONST:
        cdef uint64_t ret
        cdef uint32_t physAddr
        (<Paging>(<Segments>self.segments).paging).instrFetch = True
        physAddr = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
        IF (CPU_CACHE_SIZE):
            if (self.cacheDisabled):
                ret = self.mmReadValueUnsigned(self.regs[CPU_REGISTER_EIP]._union.dword.erx, numBytes, &self.segments.cs, False)
            else:
                self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, numBytes, &self.segments.cs, False, False, True)
                if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < numBytes):
                    self.reloadCpuCache()
                ret = self.readFromCacheAddUnsigned(numBytes)
        ELSE:
            ret = self.mmReadValueUnsigned(self.regs[CPU_REGISTER_EIP]._union.dword.erx, numBytes, &self.segments.cs, False)
        IF COMP_DEBUG:
            with gil:
                if (self.main.debugEnabled):
                    self.main.notice("Registers::getCurrentOpcodeAddUnsigned: EIP: {0:#010x}, ret=={1:#04x}", self.regs[CPU_REGISTER_EIP]._union.dword.erx, ret)
        self.regs[CPU_REGISTER_EIP]._union.dword.erx += numBytes
        return ret
    cdef uint8_t segWrite(self, uint16_t segId, uint16_t segValue) nogil except BITMASK_BYTE_CONST:
        cdef Segment *segment
        if (segId == CPU_SEGMENT_CS):
            segment = &self.segments.cs
        elif (segId == CPU_SEGMENT_SS):
            segment = &self.segments.ss
        elif (segId == CPU_SEGMENT_DS):
            segment = &self.segments.ds
        elif (segId == CPU_SEGMENT_ES):
            segment = &self.segments.es
        elif (segId == CPU_SEGMENT_FS):
            segment = &self.segments.fs
        elif (segId == CPU_SEGMENT_GS):
            segment = &self.segments.gs
        elif (segId == CPU_SEGMENT_TSS):
            segment = &self.segments.tss
        else:
            with gil:
                self.main.exitError("Segments::getSegment_1: segId {0:d} doesn't exist.", segId)
            return False
        return self.segWriteSegment(segment, segValue)
    cdef uint8_t segWriteSegment(self, Segment *segment, uint16_t segValue) nogil except BITMASK_BYTE_CONST:
        cdef uint16_t segId
        cdef uint8_t protectedModeOn, segType
        protectedModeOn = (self.protectedModeOn and not self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm)
        if (protectedModeOn and segValue > 3):
            segType = self.segments.getSegType(segValue)
            if (segType & GDT_ACCESS_NORMAL_SEGMENT and not (segType & GDT_ACCESS_ACCESSED)):
                segType |= GDT_ACCESS_ACCESSED
                self.segments.setSegType(segValue, segType)
        segId = segment[0].segId
        if (protectedModeOn):
            if (not (<Segments>self.segments).checkSegmentLoadAllowed(segValue, segId)):
                segment[0].useGDT = segment[0].gdtEntry.base = segment[0].gdtEntry.limit = segment[0].gdtEntry.accessByte = segment[0].gdtEntry.flags = \
                  segment[0].gdtEntry.segSize = segment[0].isValid = segment[0].gdtEntry.segPresent = segment[0].gdtEntry.segIsCodeSeg = \
                  segment[0].gdtEntry.segIsRW = segment[0].gdtEntry.segIsConforming = segment[0].gdtEntry.segIsNormal = \
                  segment[0].gdtEntry.segUse4K = segment[0].gdtEntry.segDPL = segment[0].gdtEntry.anotherLimit = segment[0].segIsGDTandNormal = 0
            else:
                self.segments.loadSegment(segment, segValue, False)
        else:
            self.segments.loadSegment(segment, segValue, False)
        if (segId == CPU_SEGMENT_CS):
            self.main.cpu.codeSegSize = segment[0].gdtEntry.segSize
            if (self.protectedModeOn):
                if (self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
                    self.cpl = 3
                elif (segment[0].isValid and segment[0].useGDT):
                    self.cpl = segValue & 0x3
                else:
                    with gil:
                        self.main.exitError("Registers::segWriteSegment: segment seems to be invalid!")
                    return False
            else:
                self.cpl = 0
            IF (CPU_CACHE_SIZE):
                if (not self.cacheDisabled):
                    self.cpuCacheCodeSegChange = True
        elif (segId == CPU_SEGMENT_SS):
            self.ssInhibit = True
        self.regs[CPU_SEGMENT_BASE+segId]._union.word._union.rx = segValue
        return True
    cdef int64_t regReadSigned(self, uint16_t regId, uint8_t regSize) nogil:
        if (regSize == OP_SIZE_BYTE):
            return self.regReadSignedLowByte(regId)
        elif (regSize == OP_SIZE_WORD):
            return self.regReadSignedWord(regId)
        elif (regSize == OP_SIZE_DWORD):
            return self.regReadSignedDword(regId)
        elif (regSize == OP_SIZE_QWORD):
            return self.regReadSignedQword(regId)
        return 0
    cdef uint64_t regReadUnsigned(self, uint16_t regId, uint8_t regSize) nogil:
        if (regSize == OP_SIZE_BYTE):
            return self.regReadUnsignedLowByte(regId)
        elif (regSize == OP_SIZE_WORD):
            if (regId == CPU_REGISTER_FLAGS):
                return <uint16_t>self.readFlags()
            return self.regReadUnsignedWord(regId)
        elif (regSize == OP_SIZE_DWORD):
            if (regId == CPU_REGISTER_EFLAGS):
                return self.readFlags()
            return self.regReadUnsignedDword(regId)
        elif (regSize == OP_SIZE_QWORD):
            #if (regId == CPU_REGISTER_RFLAGS): # this isn't used yet.
            #    return self.readFlags()
            return self.regReadUnsignedQword(regId)
        return 0
    cdef void regWrite(self, uint16_t regId, uint64_t value, uint8_t regSize) nogil:
        if (regSize == OP_SIZE_BYTE):
            self.regWriteLowByte(regId, value)
        elif (regSize == OP_SIZE_WORD):
            self.regWriteWord(regId, value)
        elif (regSize == OP_SIZE_DWORD):
            self.regWriteDword(regId, value)
        elif (regSize == OP_SIZE_QWORD):
            self.regWriteQword(regId, value)
    cdef uint16_t regWriteWord(self, uint16_t regId, uint16_t value) nogil except? BITMASK_BYTE_CONST:
        IF (CPU_CACHE_SIZE):
            cdef uint32_t realNewEip
        if (regId == CPU_REGISTER_EFLAGS):
            value &= ~RESERVED_FLAGS_BITMASK
            value |= FLAG_REQUIRED
            self.setFlags(value)
        self.regs[regId]._union.word._union.rx = value
        if (regId == CPU_REGISTER_EIP and not self.segments.isAddressInLimit(&self.segments.cs.gdtEntry, value, OP_SIZE_BYTE)):
            with gil:
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        IF (CPU_CACHE_SIZE):
            if (not self.cacheDisabled and regId == CPU_REGISTER_EIP):
                realNewEip = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
                if (not self.cpuCacheCodeSegChange and realNewEip >= self.cpuCacheBase and realNewEip+OP_SIZE_BYTE <= self.cpuCacheBase+self.cpuCacheSize):
                    self.cpuCacheIndex = realNewEip - self.cpuCacheBase
                else:
                #IF 1: # TODO: HACK
                    self.reloadCpuCache()
        return value # returned value is unsigned!!
    cdef uint32_t regWriteDword(self, uint16_t regId, uint32_t value) nogil except? BITMASK_BYTE_CONST:
        IF (CPU_CACHE_SIZE):
            cdef uint32_t realNewEip
        if (regId == CPU_REGISTER_CR0):
            value |= 0x10
            value &= <uint32_t>0xe005003f
        elif (regId == CPU_REGISTER_DR6):
            value &= ~(1 << 12)
            value |= <uint32_t>0xfffe0ff0
        elif (regId == CPU_REGISTER_DR7):
            value &= ~(<uint32_t>0xd000)
            value |= (1 << 10)
        elif (regId == CPU_REGISTER_EFLAGS):
            value &= ~RESERVED_FLAGS_BITMASK
            value |= FLAG_REQUIRED
            self.setFlags(value)
        self.regs[regId]._union.dword.erx = value
        if (regId == CPU_REGISTER_EIP and not self.segments.isAddressInLimit(&self.segments.cs.gdtEntry, value, OP_SIZE_BYTE)):
            with gil:
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        IF (CPU_CACHE_SIZE):
            if (not self.cacheDisabled and regId == CPU_REGISTER_EIP):
                realNewEip = self.segments.cs.gdtEntry.base+self.regs[CPU_REGISTER_EIP]._union.dword.erx
                if (not self.cpuCacheCodeSegChange and realNewEip >= self.cpuCacheBase and realNewEip+OP_SIZE_BYTE <= self.cpuCacheBase+self.cpuCacheSize):
                    self.cpuCacheIndex = realNewEip - self.cpuCacheBase
                else:
                #IF 1: # TODO: HACK
                    self.reloadCpuCache()
            #elif (regId == CPU_REGISTER_EFLAGS):
            #    self.reloadCpuCache()
        return value # returned value is unsigned!!
    cdef inline uint64_t regAdd(self, uint16_t regId, uint64_t value, uint8_t regSize) nogil:
        if (regSize == OP_SIZE_WORD):
            return self.regAddWord(regId, value)
        elif (regSize == OP_SIZE_DWORD):
            return self.regAddDword(regId, value)
        elif (regSize == OP_SIZE_QWORD):
            return self.regAddQword(regId, value)
        return 0
    cdef inline uint64_t regSub(self, uint16_t regId, uint64_t value, uint8_t regSize) nogil:
        if (regSize == OP_SIZE_WORD):
            return self.regSubWord(regId, value)
        elif (regSize == OP_SIZE_DWORD):
            return self.regSubDword(regId, value)
        elif (regSize == OP_SIZE_QWORD):
            return self.regSubQword(regId, value)
        return 0
    cdef inline uint8_t regWriteWithOpLowByte(self, uint16_t regId, uint8_t value, uint8_t valueOp) nogil:
        if (valueOp == OPCODE_SAVE):
            return self.regWriteLowByte(regId, value)
        elif (valueOp == OPCODE_ADD):
            return self.regAddLowByte(regId, value)
        elif (valueOp == OPCODE_ADC):
            return self.regAdcLowByte(regId, value)
        elif (valueOp == OPCODE_SUB):
            return self.regSubLowByte(regId, value)
        elif (valueOp == OPCODE_SBB):
            return self.regSbbLowByte(regId, value)
        elif (valueOp == OPCODE_AND):
            return self.regAndLowByte(regId, value)
        elif (valueOp == OPCODE_OR):
            return self.regOrLowByte(regId, value)
        elif (valueOp == OPCODE_XOR):
            return self.regXorLowByte(regId, value)
        elif (valueOp == OPCODE_NEG):
            value = (-value)
            return self.regWriteLowByte(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = (~value)
            return self.regWriteLowByte(regId, value)
        #else:
        #    self.main.notice("REGISTERS::regWriteWithOpLowByte: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef inline uint8_t regWriteWithOpHighByte(self, uint16_t regId, uint8_t value, uint8_t valueOp) nogil:
        if (valueOp == OPCODE_SAVE):
            return self.regWriteHighByte(regId, value)
        elif (valueOp == OPCODE_ADD):
            return self.regAddHighByte(regId, value)
        elif (valueOp == OPCODE_ADC):
            return self.regAdcHighByte(regId, value)
        elif (valueOp == OPCODE_SUB):
            return self.regSubHighByte(regId, value)
        elif (valueOp == OPCODE_SBB):
            return self.regSbbHighByte(regId, value)
        elif (valueOp == OPCODE_AND):
            return self.regAndHighByte(regId, value)
        elif (valueOp == OPCODE_OR):
            return self.regOrHighByte(regId, value)
        elif (valueOp == OPCODE_XOR):
            return self.regXorHighByte(regId, value)
        elif (valueOp == OPCODE_NEG):
            value = (-value)
            return self.regWriteHighByte(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = (~value)
            return self.regWriteHighByte(regId, value)
        #else:
        #    self.main.notice("REGISTERS::regWriteWithOpHighByte: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef inline uint16_t regWriteWithOpWord(self, uint16_t regId, uint16_t value, uint8_t valueOp) nogil:
        if (valueOp == OPCODE_SAVE):
            return self.regWriteWord(regId, value)
        elif (valueOp == OPCODE_ADD):
            return self.regAddWord(regId, value)
        elif (valueOp == OPCODE_ADC):
            return self.regAdcWord(regId, value)
        elif (valueOp == OPCODE_SUB):
            return self.regSubWord(regId, value)
        elif (valueOp == OPCODE_SBB):
            return self.regSbbWord(regId, value)
        elif (valueOp == OPCODE_AND):
            return self.regAndWord(regId, value)
        elif (valueOp == OPCODE_OR):
            return self.regOrWord(regId, value)
        elif (valueOp == OPCODE_XOR):
            return self.regXorWord(regId, value)
        elif (valueOp == OPCODE_NEG):
            value = (-value)
            return self.regWriteWord(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = (~value)
            return self.regWriteWord(regId, value)
        #else:
        #    self.main.notice("REGISTERS::regWriteWithOpWord: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef inline uint32_t regWriteWithOpDword(self, uint16_t regId, uint32_t value, uint8_t valueOp) nogil:
        if (valueOp == OPCODE_SAVE):
            return self.regWriteDword(regId, value)
        elif (valueOp == OPCODE_ADD):
            return self.regAddDword(regId, value)
        elif (valueOp == OPCODE_ADC):
            return self.regAdcDword(regId, value)
        elif (valueOp == OPCODE_SUB):
            return self.regSubDword(regId, value)
        elif (valueOp == OPCODE_SBB):
            return self.regSbbDword(regId, value)
        elif (valueOp == OPCODE_AND):
            return self.regAndDword(regId, value)
        elif (valueOp == OPCODE_OR):
            return self.regOrDword(regId, value)
        elif (valueOp == OPCODE_XOR):
            return self.regXorDword(regId, value)
        elif (valueOp == OPCODE_NEG):
            value = (-value)
            return self.regWriteDword(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = (~value)
            return self.regWriteDword(regId, value)
        #else:
        #    self.main.notice("REGISTERS::regWriteWithOpDword: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef inline uint64_t regWriteWithOpQword(self, uint16_t regId, uint64_t value, uint8_t valueOp) nogil:
        if (valueOp == OPCODE_SAVE):
            return self.regWriteQword(regId, value)
        elif (valueOp == OPCODE_ADD):
            return self.regAddQword(regId, value)
        elif (valueOp == OPCODE_ADC):
            return self.regAdcQword(regId, value)
        elif (valueOp == OPCODE_SUB):
            return self.regSubQword(regId, value)
        elif (valueOp == OPCODE_SBB):
            return self.regSbbQword(regId, value)
        elif (valueOp == OPCODE_AND):
            return self.regAndQword(regId, value)
        elif (valueOp == OPCODE_OR):
            return self.regOrQword(regId, value)
        elif (valueOp == OPCODE_XOR):
            return self.regXorQword(regId, value)
        elif (valueOp == OPCODE_NEG):
            value = (-value)
            return self.regWriteQword(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = (~value)
            return self.regWriteQword(regId, value)
        #else:
        #    self.main.notice("REGISTERS::regWriteWithOpQword: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef inline void setSZP(self, uint32_t value, uint8_t regSize) nogil:
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = (value>>((regSize<<3)-1))!=0
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = value==0
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf = PARITY_TABLE[<uint8_t>value]
    cdef inline void setSZP_O(self, uint32_t value, uint8_t regSize) nogil:
        self.setSZP(value, regSize)
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = False
    cdef inline void setSZP_A(self, uint32_t value, uint8_t regSize) nogil:
        self.setSZP(value, regSize)
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = False
    cdef inline void setSZP_COA(self, uint32_t value, uint8_t regSize) nogil:
        self.setSZP(value, regSize)
        self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = False
    cdef inline uint8_t getRegNameWithFlags(self, uint8_t modRMflags, uint8_t reg, uint8_t operSize) nogil except BITMASK_BYTE_CONST:
        cdef uint8_t regName
        if (modRMflags == MODRM_FLAGS_SREG):
            regName = CPU_REGISTER_SREG[reg]
        elif (modRMflags == MODRM_FLAGS_CREG):
            regName = CPU_REGISTER_CREG[reg]
        elif (modRMflags == MODRM_FLAGS_DREG):
            if (reg in (4, 5)):
                if (self.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_DE) != 0):
                    with gil:
                        raise HirnwichseException(CPU_EXCEPTION_UD)
                else:
                    reg += 2
            regName = CPU_REGISTER_DREG[reg]
        else:
            regName = reg
            if (operSize == OP_SIZE_BYTE):
                regName &= 3
        if (regName == CPU_REGISTER_NONE):
            with gil:
                raise HirnwichseException(CPU_EXCEPTION_UD)
        return regName
    cdef inline uint8_t getCond(self, uint8_t index) nogil:
        cdef uint8_t negateCheck, ret # = 0
        negateCheck = index & 1
        index >>= 1
        if (index == 0x0): # O
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of
        elif (index == 0x1): # B
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        elif (index == 0x2): # Z
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf
        elif (index == 0x3): # BE
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf or self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf
        elif (index == 0x4): # S
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf
        elif (index == 0x5): # P
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf
        elif (index == 0x6): # L
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf != self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of
        elif (index == 0x7): # LE
            ret = self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf or self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf != self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of
        #else:
        #    self.main.exitError("getCond: index {0:#04x} is invalid.", index)
        if (negateCheck):
            ret = not ret
        return ret
    cdef inline void setFullFlags(self, uint64_t reg0, uint64_t reg1, uint8_t regSize, uint8_t method) nogil:
        cdef uint8_t unsignedOverflow, reg0Nibble, regSumuNibble, carried = False
        cdef uint64_t regSumu
        if (method in (OPCODE_ADD, OPCODE_ADC, OPCODE_SUB, OPCODE_SBB, OPCODE_MUL, OPCODE_IMUL)):
            if (method in (OPCODE_ADC, OPCODE_SBB) and self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf):
                carried = True
            if (regSize == OP_SIZE_BYTE):
                reg0 = <uint8_t>reg0
                reg1 = <uint8_t>reg1
            elif (regSize == OP_SIZE_WORD):
                reg0 = <uint16_t>reg0
                reg1 = <uint16_t>reg1
            elif (regSize == OP_SIZE_DWORD):
                reg0 = <uint32_t>reg0
                reg1 = <uint32_t>reg1
            if (method in (OPCODE_MUL, OPCODE_IMUL)):
                if (regSize == OP_SIZE_BYTE):
                    if (method == OPCODE_MUL):
                        regSumu = (<uint8_t>reg0*reg1)
                        unsignedOverflow = (<uint16_t>regSumu)!=(<uint8_t>regSumu)
                    else:
                        regSumu = (<int8_t>reg0*reg1)
                        unsignedOverflow = (<int16_t>regSumu)!=(<int8_t>regSumu)
                    regSumu = <uint8_t>regSumu
                elif (regSize == OP_SIZE_WORD):
                    if (method == OPCODE_MUL):
                        regSumu = (<uint16_t>reg0*reg1)
                        unsignedOverflow = (<uint32_t>regSumu)!=(<uint16_t>regSumu)
                    else:
                        regSumu = (<int16_t>reg0*reg1)
                        unsignedOverflow = (<int32_t>regSumu)!=(<int16_t>regSumu)
                    regSumu = <uint16_t>regSumu
                elif (regSize == OP_SIZE_DWORD):
                    if (method == OPCODE_MUL):
                        regSumu = (<uint32_t>reg0*reg1)
                        unsignedOverflow = (<uint64_t>regSumu)!=(<uint32_t>regSumu)
                    else:
                        regSumu = (<int32_t>reg0*reg1)
                        unsignedOverflow = (<int64_t>regSumu)!=(<int32_t>regSumu)
                    regSumu = <uint32_t>regSumu
            else:
                if (carried): reg1 += 1
                if (method in (OPCODE_ADD, OPCODE_ADC)):
                    regSumu = (reg0+reg1)
                elif (method in (OPCODE_SUB, OPCODE_SBB)):
                    regSumu = (reg0-reg1)
                if (regSize == OP_SIZE_BYTE):
                    unsignedOverflow = regSumu!=(<uint8_t>regSumu)
                    regSumu = <uint8_t>regSumu
                elif (regSize == OP_SIZE_WORD):
                    unsignedOverflow = regSumu!=(<uint16_t>regSumu)
                    regSumu = <uint16_t>regSumu
                elif (regSize == OP_SIZE_DWORD):
                    unsignedOverflow = regSumu!=(<uint32_t>regSumu)
                    regSumu = <uint32_t>regSumu
            self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf = PARITY_TABLE[<uint8_t>regSumu]
            self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = not regSumu
            if (method in (OPCODE_MUL, OPCODE_IMUL)):
                self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = False
                self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = unsignedOverflow
                regSumu >>= (regSize<<3)-1
            else:
                reg0Nibble = reg0&0xf
                regSumuNibble = regSumu&0xf
                reg0 >>= (regSize<<3)-1
                reg1 >>= (regSize<<3)-1
                regSumu >>= (regSize<<3)-1
                if (method in (OPCODE_ADD, OPCODE_ADC)):
                    self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = (regSumuNibble<(reg0Nibble+carried))
                    self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = regSumu not in (reg0, reg1)
                elif (method in (OPCODE_SUB, OPCODE_SBB)):
                    self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = ((regSumuNibble+carried)>reg0Nibble)
                    self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = (reg0!=reg1 and reg0!=regSumu and reg1==regSumu)
            self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = unsignedOverflow
            self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = regSumu
    cdef inline uint32_t mmGetRealAddr(self, uint32_t mmAddr, uint32_t dataSize, Segment *segment, uint8_t allowOverride, uint8_t written, uint8_t noAddress) nogil except? BITMASK_BYTE_CONST:
        cdef uint8_t addrInLimit
        cdef uint16_t segId, segVal
        cdef uint32_t origMmAddr
        origMmAddr = mmAddr
        if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
            segment = self.main.cpu.segmentOverridePrefix
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmGetRealAddr_1: {0:s}: LIN {1:#010x}; dataSize {2:d}", "WR" if (written) else "RD", origMmAddr, dataSize)
        if (segment is not NULL):
            segId = segment[0].segId
            IF COMP_DEBUG:
                if (self.main.debugEnabled):
                    with gil:
                        self.main.notice("Registers::mmGetRealAddr_1.1: {0:s}: LIN {1:#010x}; dataSize {2:d}; segId {3:d}", "WR" if (written) else "RD", origMmAddr, dataSize, segId)
            if (self.protectedModeOn and segId == CPU_SEGMENT_TSS):
                (<Paging>(<Segments>self.segments).paging).implicitSV = True
            segVal = segment[0].segmentIndex
            addrInLimit = self.segments.isAddressInLimit(&segment[0].gdtEntry, mmAddr, dataSize)
            if (not addrInLimit):
                if (not self.ignoreExceptions):
                    with gil:
                        if (segId == CPU_SEGMENT_SS):
                            raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                        else:
                            raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                else:
                    self.ignoreExceptions = False
                return BITMASK_BYTE
            if ((written and not segment[0].writeChecked) or (not written and not segment[0].readChecked)):
                if (segment[0].useGDT):
                    if (not (segVal&0xfff8) or not segment[0].gdtEntry.segPresent):
                        with gil:
                            if (segId == CPU_SEGMENT_SS):
                                #self.main.notice("Registers::checkMemAccessRights: test1.1.1")
                                raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                            elif (not segment[0].gdtEntry.segPresent):
                                #self.main.notice("Registers::checkMemAccessRights: test1.1.2")
                                raise HirnwichseException(CPU_EXCEPTION_NP, segVal)
                            else:
                                #self.main.notice("Registers::checkMemAccessRights: test1.1.3")
                                raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                if (written):
                    if (segment[0].segIsGDTandNormal and (segment[0].gdtEntry.segIsCodeSeg or not segment[0].gdtEntry.segIsRW)):
                        #self.main.notice("Registers::checkMemAccessRights: test1.3")
                        #self.main.notice("Registers::checkMemAccessRights: test1.3.1; c0=={0:d}; c1=={1:d}; c2=={2:d}", segment[0].gdtEntry.segIsNormal, (segment[0].gdtEntry.segIsCodeSeg or not segment[0].gdtEntry.segIsRW), not addrInLimit)
                        #self.main.notice("Registers::checkMemAccessRights: test1.3.2; mmAddr=={0:#010x}; dataSize=={1:d}; base=={2:#010x}; limit=={3:#010x}", mmAddr, dataSize, segment[0].gdtEntry.base, segment[0].gdtEntry.limit)
                        with gil:
                            if (segId == CPU_SEGMENT_SS):
                                raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                            else:
                                raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                    segment[0].writeChecked = True
                else:
                    if (segment[0].segIsGDTandNormal and segment[0].gdtEntry.segIsCodeSeg and not segment[0].gdtEntry.segIsRW):
                        #self.main.notice("Registers::checkMemAccessRights: test1.4")
                        with gil:
                            if (segId == CPU_SEGMENT_SS):
                                raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                            else:
                                raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                    segment[0].readChecked = True
            mmAddr += segment[0].gdtEntry.base
        if (noAddress):
            return True
        # TODO: check for limit asf...
        if (self.protectedModeOn and self.pagingOn): # TODO: is a20 even being applied after paging is enabled? (on the physical address... or even the virtual one?)
            mmAddr = (<Paging>(<Segments>self.segments).paging).getPhysicalAddress(mmAddr, dataSize, written)
        if (not self.A20Active): # A20 Active? if True == on, else off
            mmAddr &= <uint32_t>0xffefffff
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmGetRealAddr_2: {0:s}: LIN {1:#010x}; PHY {2:#010x}", "WR" if (written) else "RD", origMmAddr, mmAddr)
        return mmAddr
    cdef int64_t mmReadValueSigned(self, uint32_t mmAddr, uint8_t dataSize, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST:
        cdef uint8_t i
        cdef uint32_t physAddr
        cdef int64_t ret
        if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
            physAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
        elif (segment is not NULL):
            physAddr = segment[0].gdtEntry.base+mmAddr
        else:
            physAddr = mmAddr
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
            ret = 0
            for i in range(dataSize):
                ret |= <int64_t>self.mmReadValueUnsignedByte(mmAddr+i, segment, allowOverride)<<(i<<3)
            if (dataSize == OP_SIZE_BYTE):
                return <int8_t>ret
            elif (dataSize == OP_SIZE_WORD):
                return <int16_t>ret
            elif (dataSize == OP_SIZE_DWORD):
                return <int32_t>ret
            return <int64_t>ret
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, False, False)
        ret = self.main.mm.mmPhyReadValueSigned(physAddr, dataSize)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmReadValueSigned: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, dataSize)
        return ret
    cdef inline uint8_t mmReadValueUnsignedByte(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST:
        cdef uint8_t ret
        #if (self.main.debugEnabled):
        #    with gil:
        #        self.main.notice("Registers::mmReadValueUnsignedByte_1: virt mmAddr {0:#010x}; dataSize {1:d}", mmAddr, OP_SIZE_BYTE)
        ret = self.main.mm.mmPhyReadValueUnsignedByte(self.mmGetRealAddr(mmAddr, OP_SIZE_BYTE, segment, allowOverride, False, False))
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmReadValueUnsignedByte_2: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, OP_SIZE_BYTE)
        return ret
    cdef uint16_t mmReadValueUnsignedWord(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST:
        cdef uint16_t ret
        cdef uint32_t physAddr
        if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
            physAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
        elif (segment is not NULL):
            physAddr = segment[0].gdtEntry.base+mmAddr
        else:
            physAddr = mmAddr
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_WORD):
            ret = <uint16_t>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
            ret |= <uint16_t>self.mmReadValueUnsignedByte(mmAddr+1, segment, allowOverride)<<8
            return ret
        physAddr = self.mmGetRealAddr(mmAddr, OP_SIZE_WORD, segment, allowOverride, False, False)
        ret = self.main.mm.mmPhyReadValueUnsignedWord(physAddr)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmReadValueUnsignedWord: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, OP_SIZE_WORD)
        return ret
    cdef uint32_t mmReadValueUnsignedDword(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST:
        cdef uint32_t ret, physAddr
        if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
            physAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
        elif (segment is not NULL):
            physAddr = segment[0].gdtEntry.base+mmAddr
        else:
            physAddr = mmAddr
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_DWORD):
            ret = <uint32_t>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
            ret |= <uint32_t>self.mmReadValueUnsignedByte(mmAddr+1, segment, allowOverride)<<8
            ret |= <uint32_t>self.mmReadValueUnsignedByte(mmAddr+2, segment, allowOverride)<<16
            ret |= <uint32_t>self.mmReadValueUnsignedByte(mmAddr+3, segment, allowOverride)<<24
            return ret
        physAddr = self.mmGetRealAddr(mmAddr, OP_SIZE_DWORD, segment, allowOverride, False, False)
        ret = self.main.mm.mmPhyReadValueUnsignedDword(physAddr)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmReadValueUnsignedDword: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, OP_SIZE_DWORD)
        return ret
    cdef uint64_t mmReadValueUnsignedQword(self, uint32_t mmAddr, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST:
        cdef uint32_t physAddr
        cdef uint64_t ret
        if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
            physAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
        elif (segment is not NULL):
            physAddr = segment[0].gdtEntry.base+mmAddr
        else:
            physAddr = mmAddr
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_QWORD):
            ret = <uint64_t>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
            ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+1, segment, allowOverride)<<8
            ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+2, segment, allowOverride)<<16
            ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+3, segment, allowOverride)<<24
            ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+4, segment, allowOverride)<<32
            ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+5, segment, allowOverride)<<40
            ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+6, segment, allowOverride)<<48
            ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+7, segment, allowOverride)<<56
            return ret
        physAddr = self.mmGetRealAddr(mmAddr, OP_SIZE_QWORD, segment, allowOverride, False, False)
        ret = self.main.mm.mmPhyReadValueUnsignedQword(physAddr)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmReadValueUnsignedQword: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, OP_SIZE_QWORD)
        return ret
    cdef uint64_t mmReadValueUnsigned(self, uint32_t mmAddr, uint8_t dataSize, Segment *segment, uint8_t allowOverride) nogil except? BITMASK_BYTE_CONST:
        cdef uint8_t i
        cdef uint32_t physAddr
        cdef uint64_t ret
        if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
            physAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
        elif (segment is not NULL):
            physAddr = segment[0].gdtEntry.base+mmAddr
        else:
            physAddr = mmAddr
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
            ret = 0
            for i in range(dataSize):
                ret |= <uint64_t>self.mmReadValueUnsignedByte(mmAddr+i, segment, allowOverride)<<(i<<3)
            return ret
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, False, False)
        ret = self.main.mm.mmPhyReadValueUnsigned(physAddr, dataSize)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmReadValueUnsigned: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, dataSize)
        return ret
    cdef uint8_t mmWriteValue(self, uint32_t mmAddr, uint64_t data, uint8_t dataSize, Segment *segment, uint8_t allowOverride) nogil except BITMASK_BYTE_CONST:
        cdef uint8_t retVal, i
        cdef uint32_t physAddr
        if (allowOverride and self.main.cpu.segmentOverridePrefix is not NULL):
            physAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
        elif (segment is not NULL):
            physAddr = segment[0].gdtEntry.base+mmAddr
        else:
            physAddr = mmAddr
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmWriteValue: virt mmAddr {0:#010x}; data {1:#010x}; dataSize {2:d}", mmAddr, data, dataSize)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
            for i in range(dataSize):
                self.mmWriteValue(mmAddr+i, <uint8_t>data, OP_SIZE_BYTE, segment, allowOverride)
                data >>= 8
            return True
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, True, False)
        retVal = self.main.mm.mmPhyWriteValue(physAddr, data, dataSize)
        IF CPU_CACHE_SIZE:
            if (not self.cacheDisabled):
                self.checkCache(physAddr, dataSize)
        return retVal
    cdef uint64_t mmWriteValueWithOp(self, uint32_t mmAddr, uint64_t data, uint8_t dataSize, Segment *segment, uint8_t allowOverride, uint8_t valueOp) nogil except? BITMASK_BYTE_CONST:
        cdef uint64_t oldData
        if (valueOp != OPCODE_SAVE):
            if (valueOp == OPCODE_NEG):
                data = (-data)
            elif (valueOp == OPCODE_NOT):
                data = (~data)
            else:
                oldData = self.mmReadValueUnsigned(mmAddr, dataSize, segment, allowOverride)
                if (valueOp == OPCODE_ADD):
                    data = (oldData+data)
                elif (valueOp == OPCODE_SUB):
                    data = (oldData-data)
                elif (valueOp == OPCODE_AND):
                    data = (oldData&data)
                elif (valueOp == OPCODE_OR):
                    data = (oldData|data)
                elif (valueOp == OPCODE_XOR):
                    data = (oldData^data)
                elif (valueOp in (OPCODE_ADC, OPCODE_SBB)):
                    data += self.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
                    if (valueOp == OPCODE_ADC):
                        data = (oldData+data)
                    else:
                        data = (oldData-data)
                #else:
                #    self.main.exitError("Registers::mmWriteValueWithOp: unknown valueOp {0:d}.", valueOp)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmWriteValueWithOp: virt mmAddr {0:#010x}; data {1:#010x}; dataSize {2:d}", mmAddr, data, dataSize)
        self.mmWriteValue(mmAddr, data, dataSize, segment, allowOverride)
        return data
    cdef uint8_t switchTSS16(self) nogil except BITMASK_BYTE_CONST:
        cdef uint32_t baseAddress
        cdef GdtEntry gdtEntry
        with gil:
            self.main.notice("Registers::switchTSS16: TODO? (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        baseAddress = self.mmGetRealAddr(0, 1, &self.segments.tss, False, False, False)
        if (((baseAddress&0xfff)+TSS_MIN_16BIT_HARD_LIMIT) > 0xfff):
            with gil:
                self.main.exitError("Registers::switchTSS16: TSS is over page boundary!")
            return False
        self.ldtr = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_LDT_SEG_SEL)
        if (self.ldtr):
            if (not self.segments.gdt.getEntry(&gdtEntry, self.ldtr&0xfff8)):
                with gil:
                    self.main.notice("Registers::switchTSS16: gdtEntry is invalid, mark LDTR as invalid.")
                (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
            else:
                (<Gdt>self.segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
        else:
            (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
        self.segWriteSegment(&self.segments.cs, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_CS))
        self.regWriteWord(CPU_REGISTER_IP, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_IP))
        self.segWriteSegment(&self.segments.ss, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_SS))
        self.regWriteWord(CPU_REGISTER_SP, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_SP))
        if (self.regWriteWord(CPU_REGISTER_FLAGS, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_FLAGS))):
            self.main.cpu.asyncEvent = True
        self.segWriteSegment(&self.segments.ds, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_DS))
        self.segWriteSegment(&self.segments.es, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_ES))
        self.regWriteWord(CPU_REGISTER_AX, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_AX))
        self.regWriteWord(CPU_REGISTER_CX, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_CX))
        self.regWriteWord(CPU_REGISTER_DX, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_DX))
        self.regWriteWord(CPU_REGISTER_BX, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_BX))
        self.regWriteWord(CPU_REGISTER_BP, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_BP))
        self.regWriteWord(CPU_REGISTER_SI, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_SI))
        self.regWriteWord(CPU_REGISTER_DI, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_DI))
        self.regOrDword(CPU_REGISTER_CR0, CR0_FLAG_TS)
        return True
    cdef uint8_t saveTSS16(self) nogil except BITMASK_BYTE_CONST:
        cdef uint32_t baseAddress
        with gil:
            self.main.notice("Registers::saveTSS16: TODO? (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        baseAddress = self.mmGetRealAddr(0, 1, &self.segments.tss, False, True, False)
        if (((baseAddress&0xfff)+TSS_MIN_16BIT_HARD_LIMIT) > 0xfff):
            with gil:
                self.main.exitError("Registers::saveTSS16: TSS is over page boundary!")
            return False
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_AX, self.regReadUnsignedWord(CPU_REGISTER_AX), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_CX, self.regReadUnsignedWord(CPU_REGISTER_CX), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_DX, self.regReadUnsignedWord(CPU_REGISTER_DX), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_BX, self.regReadUnsignedWord(CPU_REGISTER_BX), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_BP, self.regReadUnsignedWord(CPU_REGISTER_BP), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_SI, self.regReadUnsignedWord(CPU_REGISTER_SI), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_DI, self.regReadUnsignedWord(CPU_REGISTER_DI), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_ES, self.segRead(CPU_SEGMENT_ES), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_CS, self.segRead(CPU_SEGMENT_CS), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_DS, self.segRead(CPU_SEGMENT_DS), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_IP, self.regReadUnsignedWord(CPU_REGISTER_IP), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_FLAGS, self.readFlags(), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_SP, self.regReadUnsignedWord(CPU_REGISTER_SP), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_16BIT_SS, self.segRead(CPU_SEGMENT_SS), OP_SIZE_WORD)
        return True
    cdef uint8_t switchTSS32(self) nogil except BITMASK_BYTE_CONST:
        cdef uint32_t baseAddress, temp
        cdef GdtEntry gdtEntry
        with gil:
            self.main.notice("Registers::switchTSS32: TODO? (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
            self.main.cpu.cpuDump()
            self.main.notice("Registers::switchTSS32: TODO? (getCPL(): {0:d}; cpl: {1:d})", self.getCPL(), self.cpl)
        baseAddress = self.mmGetRealAddr(0, 1, &self.segments.tss, False, False, False)
        if (((baseAddress&0xfff)+TSS_MIN_32BIT_HARD_LIMIT) > 0xfff):
            with gil:
                self.main.exitError("Registers::switchTSS32: TSS is over page boundary!")
            return False
        if (self.protectedModeOn and self.pagingOn):
            temp = self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_CR3)
            self.regWriteDword(CPU_REGISTER_CR3, temp)
            #(<Paging>self.segments.paging).invalidateTables(temp, True)
            (<Paging>self.segments.paging).invalidateTables(temp, False)
        self.ldtr = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_LDT_SEG_SEL)
        if (self.ldtr):
            if (not self.segments.gdt.getEntry(&gdtEntry, self.ldtr&0xfff8)):
                with gil:
                    self.main.notice("Registers::switchTSS32: gdtEntry is invalid, mark LDTR as invalid.")
                (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
            else:
                (<Gdt>self.segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
        else:
            (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
        self.segWriteSegment(&self.segments.cs, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_CS))
        self.regWriteDword(CPU_REGISTER_EIP, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EIP))
        self.segWriteSegment(&self.segments.ss, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_SS))
        self.regWriteDword(CPU_REGISTER_ESP, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_ESP))
        if (self.regWriteDword(CPU_REGISTER_EFLAGS, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EFLAGS))):
            self.main.cpu.asyncEvent = True
        self.segWriteSegment(&self.segments.ds, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_DS))
        self.segWriteSegment(&self.segments.es, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_ES))
        self.segWriteSegment(&self.segments.fs, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_FS))
        self.segWriteSegment(&self.segments.gs, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_GS))
        self.regWriteDword(CPU_REGISTER_EAX, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EAX))
        self.regWriteDword(CPU_REGISTER_ECX, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_ECX))
        self.regWriteDword(CPU_REGISTER_EDX, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EDX))
        self.regWriteDword(CPU_REGISTER_EBX, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EBX))
        self.regWriteDword(CPU_REGISTER_EBP, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EBP))
        self.regWriteDword(CPU_REGISTER_ESI, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_ESI))
        self.regWriteDword(CPU_REGISTER_EDI, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EDI))
        self.regOrDword(CPU_REGISTER_CR0, CR0_FLAG_TS)
        #IF (CPU_CACHE_SIZE):
        #    self.reloadCpuCache()
        with gil:
            self.main.cpu.cpuDump()
            self.main.notice("Registers::switchTSS32: TODO? (getCPL(): {0:d}; cpl: {1:d})", self.getCPL(), self.cpl)
        if ((self.main.mm.mmPhyReadValueUnsignedByte(baseAddress + TSS_32BIT_T_FLAG) & 1) != 0):
            with gil:
                self.main.notice("Registers::switchTSS32: Debug")
                raise HirnwichseException(CPU_EXCEPTION_DB)
        return True
    cdef uint8_t saveTSS32(self) nogil except BITMASK_BYTE_CONST:
        cdef uint32_t baseAddress
        with gil:
            self.main.notice("Registers::saveTSS32: TODO? (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
            self.main.cpu.cpuDump()
            self.main.notice("Registers::saveTSS32: TODO? (getCPL(): {0:d}; cpl: {1:d})", self.getCPL(), self.cpl)
        baseAddress = self.mmGetRealAddr(0, 1, &self.segments.tss, False, True, False)
        if (((baseAddress&0xfff)+TSS_MIN_32BIT_HARD_LIMIT) > 0xfff):
            with gil:
                self.main.exitError("Registers::saveTSS32: TSS is over page boundary!")
            return False
        #self.main.debugEnabled = True
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EAX, self.regReadUnsignedDword(CPU_REGISTER_EAX), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_ECX, self.regReadUnsignedDword(CPU_REGISTER_ECX), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EDX, self.regReadUnsignedDword(CPU_REGISTER_EDX), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EBX, self.regReadUnsignedDword(CPU_REGISTER_EBX), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EBP, self.regReadUnsignedDword(CPU_REGISTER_EBP), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_ESI, self.regReadUnsignedDword(CPU_REGISTER_ESI), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EDI, self.regReadUnsignedDword(CPU_REGISTER_EDI), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_ES, self.segRead(CPU_SEGMENT_ES), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_CS, self.segRead(CPU_SEGMENT_CS), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_DS, self.segRead(CPU_SEGMENT_DS), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_FS, self.segRead(CPU_SEGMENT_FS), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_GS, self.segRead(CPU_SEGMENT_GS), OP_SIZE_WORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EIP, self.regReadUnsignedDword(CPU_REGISTER_EIP), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_EFLAGS, self.readFlags(), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_ESP, self.regReadUnsignedDword(CPU_REGISTER_ESP), OP_SIZE_DWORD)
        self.main.mm.mmPhyWriteValue(baseAddress + TSS_32BIT_SS, self.segRead(CPU_SEGMENT_SS), OP_SIZE_WORD)
        return True
    cdef void run(self):
        self.segments.run()
        self.fpu.run()



