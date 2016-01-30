
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"
include "cpu_globals.pxi"

from misc import HirnwichseException
import gmpy2, struct

# Parity Flag Table: DO NOT EDIT!!!
cdef unsigned char PARITY_TABLE[256]
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
    cdef unsigned char modRMOperands(self, unsigned char regSize, unsigned char modRMflags) nogil except BITMASK_BYTE_CONST: # regSize in bytes
        cdef unsigned char modRMByte
        modRMByte = self.registers.getCurrentOpcodeAddUnsignedByte()
        self.rmNameSeg = (<PyObject*>self.registers.segments.ds)
        self.rmName1 = CPU_REGISTER_NONE
        self.rmName2 = 0
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
        else:
            self.regSize = self.registers.addrSize
            if (self.regSize == OP_SIZE_WORD):
                self.rmName0 = CPU_MODRM_16BIT_RM0[self.rm]
                self.rmName1 = CPU_MODRM_16BIT_RM1[self.rm]
                if (self.mod == 0 and self.rm == 6):
                    self.rmName0 = CPU_REGISTER_NONE
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedWord()
                elif (self.mod == 1):
                    self.rmName2 = self.registers.getCurrentOpcodeAddSignedByte()
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedWord()
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
                    self.rmName2 = self.registers.getCurrentOpcodeAddSignedByte()
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedDword()
            if (self.rmName0 in (CPU_REGISTER_ESP, CPU_REGISTER_EBP)):
                self.rmNameSeg = (<PyObject*>self.registers.segments.ss)
        return True
    cdef unsigned long int getRMValueFull(self, unsigned char rmSize) nogil:
        cdef unsigned long int retAddr = 0
        if (self.rmName0 != CPU_REGISTER_NONE):
            if (self.regSize in (OP_SIZE_BYTE, OP_SIZE_WORD)):
                retAddr = self.registers.regReadUnsignedWord(self.rmName0)
                if (self.regSize == OP_SIZE_BYTE):
                    if (self.rm >= 4):
                        retAddr >>= 8
                    retAddr = <unsigned char>retAddr
            elif (self.regSize == OP_SIZE_DWORD):
                retAddr = self.registers.regReadUnsignedDword(self.rmName0)
            elif (self.regSize == OP_SIZE_QWORD):
                retAddr = self.registers.regReadUnsignedQword(self.rmName0)
        if (self.rmName1 != CPU_REGISTER_NONE):
            retAddr += self.registers.regReadUnsigned(self.rmName1, self.regSize)<<self.ss
        retAddr += self.rmName2
        if (rmSize == OP_SIZE_BYTE):
            return <unsigned char>retAddr
        elif (rmSize == OP_SIZE_WORD):
            return <unsigned short>retAddr
        elif (rmSize == OP_SIZE_DWORD):
            return <unsigned int>retAddr
        return retAddr
    cdef signed long int modRMLoadSigned(self, unsigned char regSize) nogil except? BITMASK_BYTE_CONST:
        # NOTE: imm == unsigned ; disp == signed
        cdef unsigned long int mmAddr
        cdef signed long int returnInt
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
            returnInt = self.registers.mmReadValueSigned(mmAddr, regSize, <Segment>self.rmNameSeg, True)
        return returnInt
    cdef unsigned long int modRMLoadUnsigned(self, unsigned char regSize) nogil except? BITMASK_BYTE_CONST:
        # NOTE: imm == unsigned ; disp == signed
        cdef unsigned long int mmAddr, returnInt = 0
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
            returnInt = self.registers.mmReadValueUnsigned(mmAddr, regSize, <Segment>self.rmNameSeg, True)
        return returnInt
    cdef unsigned long int modRMSave(self, unsigned char regSize, unsigned long int value, unsigned char valueOp) nogil except? BITMASK_BYTE_CONST:
        # stdValueOp==OPCODE_SAVE
        cdef unsigned long int mmAddr
        if (self.mod != 3):
            mmAddr = self.getRMValueFull(self.regSize)
        if (regSize == OP_SIZE_BYTE):
            value = <unsigned char>value
            if (self.mod == 3):
                if (self.rm <= 3):
                    return self.registers.regWriteWithOpLowByte(self.rmName0, value, valueOp)
                else: # self.rm >= 4
                    return self.registers.regWriteWithOpHighByte(self.rmName0, value, valueOp)
            return <unsigned char>self.registers.mmWriteValueWithOp(mmAddr, value, regSize, <Segment>self.rmNameSeg, True, valueOp)
        elif (regSize == OP_SIZE_WORD):
            value = <unsigned short>value
            if (self.mod == 3):
                return self.registers.regWriteWithOpWord(self.rmName0, value, valueOp)
            return <unsigned short>self.registers.mmWriteValueWithOp(mmAddr, value, regSize, <Segment>self.rmNameSeg, True, valueOp)
        elif (regSize == OP_SIZE_DWORD):
            value = <unsigned int>value
            if (self.mod == 3):
                return self.registers.regWriteWithOpDword(self.rmName0, value, valueOp)
            return <unsigned int>self.registers.mmWriteValueWithOp(mmAddr, value, regSize, <Segment>self.rmNameSeg, True, valueOp)
        elif (regSize == OP_SIZE_QWORD):
            if (self.mod == 3):
                return self.registers.regWriteWithOpQword(self.rmName0, value, valueOp)
            return self.registers.mmWriteValueWithOp(mmAddr, value, regSize, <Segment>self.rmNameSeg, True, valueOp)
        #self.registers.main.exitError("ModRMClass::modRMSave: if; else.")
        return 0
    cdef signed long int modRLoadSigned(self, unsigned char regSize) nogil:
        cdef signed long int retVal = 0
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
    cdef unsigned long int modRLoadUnsigned(self, unsigned char regSize) nogil:
        cdef unsigned long int retVal = 0
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
    cdef unsigned long int modRSave(self, unsigned char regSize, unsigned long int value, unsigned char valueOp) nogil:
        if (regSize == OP_SIZE_BYTE):
            value = <unsigned char>value
            if (self.reg <= 3):
                return self.registers.regWriteWithOpLowByte(self.regName, value, valueOp)
            else: #elif (self.reg >= 4):
                return self.registers.regWriteWithOpHighByte(self.regName, value, valueOp)
        elif (regSize == OP_SIZE_WORD):
            value = <unsigned short>value
            return self.registers.regWriteWithOpWord(self.regName, value, valueOp)
        elif (regSize == OP_SIZE_DWORD):
            value = <unsigned int>value
            return self.registers.regWriteWithOpDword(self.regName, value, valueOp)
        elif (regSize == OP_SIZE_QWORD):
            return self.registers.regWriteWithOpQword(self.regName, value, valueOp)


cdef class Fpu:
    def __init__(self, Registers registers, Hirnwichse main):
        self.registers = registers
        self.main = main
        self.st = [None]*8
        #self.opcode = 0
    cdef void reset(self, unsigned char fninit):
        cdef unsigned char i
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
    cdef inline unsigned char getPrecision(self):
        return FPU_PRECISION[(self.ctrl>>8)&3]
    cdef inline void setPrecision(self):
        gmpy2.get_context().precision=self.getPrecision()
    cdef inline void setCtrl(self, unsigned short ctrl):
        self.ctrl = ctrl
        self.setPrecision()
    cdef inline void setPointers(self, unsigned short opcode):
        self.opcode = opcode
        self.instSeg = self.main.cpu.savedCs
        self.instPointer = self.main.cpu.savedEip
    cdef inline void setDataPointers(self, unsigned short dataSeg, unsigned int dataPointer):
        self.dataSeg = dataSeg
        self.dataPointer = dataPointer
    cdef inline void setTag(self, unsigned short index, unsigned char tag):
        index <<= 1
        self.tag &= ~(3<<index)
        self.tag |= tag<<index
    cdef inline void setFlag(self, unsigned short index, unsigned char flag):
        index = 1<<index
        if (flag):
            self.status |= index
        else:
            self.status &= ~index
    cdef inline void setExc(self, unsigned short index, unsigned char flag):
        self.setFlag(index, flag)
        index = 1<<index
        if (flag and (self.ctrl & index) != 0):
            self.setFlag(FPU_EXCEPTION_ES, True)
    cdef inline void setC(self, unsigned short index, unsigned char flag):
        if (index < 3):
            index = 8+index
        else:
            index = 14
        self.setFlag(index, flag)
    cdef inline unsigned char getIndex(self, unsigned char index):
        return (((self.status >> 11) & 7) + index) & 7
    cdef inline void addTop(self, signed char index):
        cdef char tempIndex
        tempIndex = (self.status >> 11) & 7
        self.status &= ~(7 << 11)
        tempIndex += index
        self.status |= (tempIndex & 7) << 11
    cdef inline void setVal(self, unsigned char tempIndex, object data, unsigned char setFlags): # load
        cdef signed int tempVal
        cdef tuple tempTuple
        cdef bytes tempData
        data = gmpy2.mpfr(data)
        tempIndex = self.getIndex(tempIndex)
        if (not gmpy2.is_zero(data)):
            tempTuple = data.as_integer_ratio()
            tempVal = (tempTuple[0].bit_length()-tempTuple[1].bit_length())
            tempVal = <unsigned short>(tempVal+16383)
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
    cdef inline object getVal(self, unsigned char tempIndex): # store
        cdef unsigned char negative
        cdef unsigned int exp
        tempIndex = self.getIndex(tempIndex)
        self.main.notice("Fpu::getVal: tempIndex=={0:d}, len(st[ti])=={1:d}, repr(st[ti]=={2:s})", tempIndex, len(self.st[tempIndex]), repr(self.st[tempIndex]))
        if (self.st[tempIndex] == bytes(10)):
            return gmpy2.mpfr(0)
        exp = int.from_bytes(self.st[tempIndex][:2],byteorder="big")
        negative = (exp & 0x8000) != 0
        exp &= <unsigned short>(~(<unsigned short>0x8000))
        exp = <unsigned short>((exp-16383)+1)
        return gmpy2.from_binary(b"\x04"+bytes([ 0x43 if (negative) else 0x41 ])+b"\x00\x00"+bytes([self.getPrecision()])+b"\x00\x00\x00"+struct.pack("<I", exp)+self.st[tempIndex][9:1:-1])
    cdef inline void push(self, object data, unsigned char setFlags): # load
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
        self.regWriteDword(CPU_REGISTER_CR0, CR0_FLAG_CD | CR0_FLAG_NW | CR0_FLAG_ET)
    cdef void reset(self):
        self.operSize = self.addrSize = self.cf = self.pf = self.af = self.zf = self.sf = self.tf = \
          self.if_flag = self.df = self.of = self.iopl = self.nt = self.rf = self.vm = self.ac = \
          self.vif = self.vip = self.id = self.cpl = self.protectedModeOn = self.pagingOn = writeProtectionOn = self.A20Active = self.ssInhibit = self.cacheDisabled = self.cpuCacheBase = self.cpuCacheIndex = 0
        IF CPU_CACHE_SIZE:
            self.cpuCache = b''
        self.resetPrefixes()
        self.segments.reset()
        self.fpu.reset(False)
        self.regWriteDwordEflags(FLAG_REQUIRED)
        self.regWriteDword(CPU_REGISTER_CR0, self.getFlagDword(CPU_REGISTER_CR0, CR0_FLAG_CD | CR0_FLAG_NW) | CR0_FLAG_ET)
        #self.regWriteDword(CPU_REGISTER_DR6, 0xffff1ff0) # why has bochs bit 12 set?
        self.regWriteDword(CPU_REGISTER_DR6, 0xffff0ff0)
        self.regWriteDword(CPU_REGISTER_DR7, 0x400)
        self.regWriteDword(CPU_REGISTER_EDX, 0x521)
        self.segWriteSegment((<Segment>self.segments.cs), 0xf000)
        self.regWriteDword(CPU_REGISTER_EIP, 0xfff0)
    cdef void reloadCpuCache(self):
        IF CPU_CACHE_SIZE:
            cdef unsigned int mmAddr
            mmAddr = self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, CPU_CACHE_SIZE, (<Segment>self.segments.cs), False, False)
            self.cpuCache = self.main.mm.mmPhyRead(mmAddr, CPU_CACHE_SIZE)
            self.cpuCacheBase = mmAddr
            self.cpuCacheIndex = 0
    cdef signed long int readFromCacheAddSigned(self, unsigned char numBytes):
        cdef signed long int retVal
        retVal = int.from_bytes(self.cpuCache[self.cpuCacheIndex:self.cpuCacheIndex+numBytes], byteorder="little", signed=True)
        self.cpuCacheIndex += numBytes
        if (self.cpuCacheIndex >= CPU_CACHE_SIZE):
            self.reloadCpuCache()
        return retVal
    cdef unsigned long int readFromCacheAddUnsigned(self, unsigned char numBytes):
        cdef unsigned long int retVal
        retVal = int.from_bytes(self.cpuCache[self.cpuCacheIndex:self.cpuCacheIndex+numBytes], byteorder="little", signed=False)
        self.cpuCacheIndex += numBytes
        if (self.cpuCacheIndex >= CPU_CACHE_SIZE):
            self.reloadCpuCache()
        return retVal
    cdef unsigned long int readFromCacheUnsigned(self, unsigned char numBytes):
        cdef unsigned long int retVal
        retVal = int.from_bytes(self.cpuCache[self.cpuCacheIndex:self.cpuCacheIndex+numBytes], byteorder="little", signed=False)
        if (self.cpuCacheIndex+numBytes >= CPU_CACHE_SIZE):
            self.reloadCpuCache()
        return retVal
    cdef unsigned char getCurrentOpcodeUnsignedByte(self) nogil except? BITMASK_BYTE_CONST:
        IF (CPU_CACHE_SIZE):
            return <unsigned char>self.readFromCacheUnsigned(OP_SIZE_BYTE)
        ELSE:
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueUnsignedByte(self.regs[CPU_REGISTER_EIP]._union.dword.erx, (<Segment>self.segments.cs), False)
    cdef signed long int getCurrentOpcodeAddSigned(self, unsigned char numBytes) nogil except? BITMASK_BYTE_CONST:
        IF (CPU_CACHE_SIZE):
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += numBytes
            return self.readFromCacheAddSigned(numBytes)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += numBytes
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueSigned(opcodeAddr, numBytes, (<Segment>self.segments.cs), False)
    cdef unsigned char getCurrentOpcodeAddUnsignedByte(self) nogil except? BITMASK_BYTE_CONST:
        IF (CPU_CACHE_SIZE):
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_BYTE
            return <unsigned char>self.readFromCacheAddUnsigned(OP_SIZE_BYTE)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_BYTE
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueUnsignedByte(opcodeAddr, (<Segment>self.segments.cs), False)
    cdef unsigned short getCurrentOpcodeAddUnsignedWord(self) nogil except? BITMASK_BYTE_CONST:
        IF (CPU_CACHE_SIZE):
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_WORD
            return <unsigned short>self.readFromCacheAddUnsigned(OP_SIZE_WORD)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_WORD
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueUnsignedWord(opcodeAddr, (<Segment>self.segments.cs), False)
    cdef unsigned int getCurrentOpcodeAddUnsignedDword(self) nogil except? BITMASK_BYTE_CONST:
        IF (CPU_CACHE_SIZE):
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_DWORD
            return <unsigned int>self.readFromCacheAddUnsigned(OP_SIZE_DWORD)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_DWORD
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueUnsignedDword(opcodeAddr, (<Segment>self.segments.cs), False)
    cdef unsigned long int getCurrentOpcodeAddUnsignedQword(self) nogil except? BITMASK_BYTE_CONST:
        IF (CPU_CACHE_SIZE):
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_QWORD
            return self.readFromCacheAddUnsigned(OP_SIZE_QWORD)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += OP_SIZE_QWORD
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueUnsignedQword(opcodeAddr, (<Segment>self.segments.cs), False)
    cdef unsigned long int getCurrentOpcodeAddUnsigned(self, unsigned char numBytes) nogil except? BITMASK_BYTE_CONST:
        IF (CPU_CACHE_SIZE):
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += numBytes
            return self.readFromCacheAddUnsigned(numBytes)
        ELSE:
            cdef unsigned int opcodeAddr
            opcodeAddr = self.regs[CPU_REGISTER_EIP]._union.dword.erx
            self.regs[CPU_REGISTER_EIP]._union.dword.erx += numBytes
            (<Paging>(<Segments>self.segments).paging).setInstrFetch()
            return self.mmReadValueUnsigned(opcodeAddr, numBytes, (<Segment>self.segments.cs), False)
    cdef unsigned char segWrite(self, unsigned short segId, unsigned short segValue) except BITMASK_BYTE_CONST:
        cdef Segment segment
        cdef unsigned char protectedModeOn, segType
        protectedModeOn = (self.protectedModeOn and not self.vm)
        if (protectedModeOn and segValue > 3):
            segType = self.segments.getSegType(segValue)
            if (segType & GDT_ACCESS_NORMAL_SEGMENT and not (segType & GDT_ACCESS_ACCESSED)):
                segType |= GDT_ACCESS_ACCESSED
                self.segments.setSegType(segValue, segType)
        segment = self.segments.getSegment(segId, False)
        segment.loadSegment(segValue, False)
        if (protectedModeOn):
            if (not (<Segments>self.segments).checkSegmentLoadAllowed(segValue, segId)):
                segment.isValid = False
        if (segId == CPU_SEGMENT_CS):
            self.codeSegSize = segment.segSize
            if (self.protectedModeOn):
                if (self.vm):
                    self.cpl = 3
                elif (segment.isValid and segment.useGDT):
                    self.cpl = segValue & 0x3
                else:
                    self.main.exitError("Registers::segWrite: segment seems to be invalid!")
                    return False
            else:
                self.cpl = 0
        elif (segId == CPU_SEGMENT_SS):
            self.ssInhibit = True
        self.regs[CPU_SEGMENT_BASE+segId]._union.word._union.rx = segValue
        return True
    cdef unsigned char segWriteSegment(self, Segment segment, unsigned short segValue) nogil except BITMASK_BYTE_CONST:
        cdef unsigned short segId
        cdef unsigned char protectedModeOn, segType
        protectedModeOn = (self.protectedModeOn and not self.vm)
        if (protectedModeOn and segValue > 3):
            with gil:
                segType = self.segments.getSegType(segValue)
                if (segType & GDT_ACCESS_NORMAL_SEGMENT and not (segType & GDT_ACCESS_ACCESSED)):
                    segType |= GDT_ACCESS_ACCESSED
                    self.segments.setSegType(segValue, segType)
        segId = segment.segId
        with gil:
            segment.loadSegment(segValue, False)
            if (protectedModeOn):
                if (not (<Segments>self.segments).checkSegmentLoadAllowed(segValue, segId)):
                    segment.isValid = False
        if (segId == CPU_SEGMENT_CS):
            self.codeSegSize = segment.segSize
            if (self.vm):
                self.cpl = 3
            elif (segment.isValid and segment.useGDT):
                self.cpl = segValue & 0x3
            else:
                self.cpl = 0
        elif (segId == CPU_SEGMENT_SS):
            self.ssInhibit = True
        self.regs[CPU_SEGMENT_BASE+segId]._union.word._union.rx = segValue
        return True
    cdef signed long int regReadSigned(self, unsigned short regId, unsigned char regSize) nogil:
        if (regSize == OP_SIZE_BYTE):
            return self.regReadSignedLowByte(regId)
        elif (regSize == OP_SIZE_WORD):
            return self.regReadSignedWord(regId)
        elif (regSize == OP_SIZE_DWORD):
            return self.regReadSignedDword(regId)
        elif (regSize == OP_SIZE_QWORD):
            return self.regReadSignedQword(regId)
        return 0
    cdef unsigned long int regReadUnsigned(self, unsigned short regId, unsigned char regSize) nogil:
        if (regSize == OP_SIZE_BYTE):
            return self.regReadUnsignedLowByte(regId)
        elif (regSize == OP_SIZE_WORD):
            if (regId == CPU_REGISTER_FLAGS):
                return <unsigned short>self.readFlags()
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
    cdef void regWrite(self, unsigned short regId, unsigned long int value, unsigned char regSize) nogil:
        if (regSize == OP_SIZE_BYTE):
            self.regWriteLowByte(regId, value)
        elif (regSize == OP_SIZE_WORD):
            if (regId == CPU_REGISTER_FLAGS):
                if (self.regWriteWordFlags(<unsigned short>value)):
                    self.main.cpu.asyncEvent = True
            else:
                self.regWriteWord(regId, value)
        elif (regSize == OP_SIZE_DWORD):
            if (regId == CPU_REGISTER_EFLAGS):
                if (self.regWriteDwordEflags(<unsigned int>value)):
                    self.main.cpu.asyncEvent = True
            else:
                self.regWriteDword(regId, value)
        elif (regSize == OP_SIZE_QWORD):
            if (regId == CPU_REGISTER_RFLAGS):
                if (self.regWriteDwordEflags(<unsigned int>value)):
                    self.main.cpu.asyncEvent = True
            else:
                self.regWriteQword(regId, value)
    cdef unsigned int regWriteDword(self, unsigned short regId, unsigned int value) nogil except? BITMASK_BYTE_CONST:
        IF (CPU_CACHE_SIZE):
            cdef unsigned int realNewEip
        if (regId == CPU_REGISTER_CR0):
            value |= 0x10
            value &= <unsigned int>0xe005003f
        elif (regId == CPU_REGISTER_DR6):
            value &= ~(1 << 12)
            value |= <unsigned int>0xfffe0ff0
        elif (regId == CPU_REGISTER_DR7):
            value &= ~(<unsigned int>0xd000)
            value |= (1 << 10)
        self.regs[regId]._union.dword.erx = value
        if (regId == CPU_REGISTER_EIP and not (<Segment>self.segments.cs).isAddressInLimit(value, OP_SIZE_BYTE)):
            with gil:
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        IF (CPU_CACHE_SIZE):
            if (regId == CPU_REGISTER_EIP):
                realNewEip = self.mmGetRealAddr(self.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_DWORD, (<Segment>self.segments.cs), False, False)
                if (realNewEip >= self.cpuCacheBase and realNewEip < self.cpuCacheBase+CPU_CACHE_SIZE):
                    self.cpuCacheIndex = realNewEip - self.cpuCacheBase
                else:
                    self.reloadCpuCache()
        return value # returned value is unsigned!!
    cdef inline unsigned long int regAdd(self, unsigned short regId, unsigned long int value, unsigned char regSize) nogil:
        if (regSize == OP_SIZE_WORD):
            return self.regAddWord(regId, value)
        elif (regSize == OP_SIZE_DWORD):
            return self.regAddDword(regId, value)
        elif (regSize == OP_SIZE_QWORD):
            return self.regAddQword(regId, value)
        return 0
    cdef inline unsigned long int regSub(self, unsigned short regId, unsigned long int value, unsigned char regSize) nogil:
        if (regSize == OP_SIZE_WORD):
            return self.regSubWord(regId, value)
        elif (regSize == OP_SIZE_DWORD):
            return self.regSubDword(regId, value)
        elif (regSize == OP_SIZE_QWORD):
            return self.regSubQword(regId, value)
        return 0
    cdef inline unsigned char regWriteWithOpLowByte(self, unsigned short regId, unsigned char value, unsigned char valueOp) nogil:
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
    cdef inline unsigned char regWriteWithOpHighByte(self, unsigned short regId, unsigned char value, unsigned char valueOp) nogil:
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
    cdef inline unsigned short regWriteWithOpWord(self, unsigned short regId, unsigned short value, unsigned char valueOp) nogil:
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
    cdef inline unsigned int regWriteWithOpDword(self, unsigned short regId, unsigned int value, unsigned char valueOp) nogil:
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
    cdef inline unsigned long int regWriteWithOpQword(self, unsigned short regId, unsigned long int value, unsigned char valueOp) nogil:
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
    cdef inline void setSZP(self, unsigned int value, unsigned char regSize) nogil:
        self.sf = (value>>((regSize<<3)-1))!=0
        self.zf = value==0
        self.pf = PARITY_TABLE[<unsigned char>value]
    cdef inline void setSZP_O(self, unsigned int value, unsigned char regSize) nogil:
        self.setSZP(value, regSize)
        self.of = False
    cdef inline void setSZP_A(self, unsigned int value, unsigned char regSize) nogil:
        self.setSZP(value, regSize)
        self.af = False
    cdef inline void setSZP_COA(self, unsigned int value, unsigned char regSize) nogil:
        self.setSZP(value, regSize)
        self.cf = self.of = self.af = False
    cdef inline unsigned char getRegNameWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize) nogil except BITMASK_BYTE_CONST:
        cdef unsigned char regName
        regName = CPU_REGISTER_NONE
        if (modRMflags & MODRM_FLAGS_SREG):
            regName = CPU_REGISTER_SREG[reg]
        elif (modRMflags & MODRM_FLAGS_CREG):
            regName = CPU_REGISTER_CREG[reg]
        elif (modRMflags & MODRM_FLAGS_DREG):
            if (reg in (4, 5) and self.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_DE) != 0):
                with gil:
                    raise HirnwichseException(CPU_EXCEPTION_UD)
            regName = CPU_REGISTER_DREG[reg]
        else:
            regName = reg
            if (operSize == OP_SIZE_BYTE):
                regName &= 3
        if (regName == CPU_REGISTER_NONE):
            with gil:
                raise HirnwichseException(CPU_EXCEPTION_UD)
        return regName
    cdef inline unsigned char getCond(self, unsigned char index) nogil:
        cdef unsigned char negateCheck, ret = 0
        negateCheck = index & 1
        index >>= 1
        if (index == 0x0): # O
            ret = self.of
        elif (index == 0x1): # B
            ret = self.cf
        elif (index == 0x2): # Z
            ret = self.zf
        elif (index == 0x3): # BE
            ret = self.cf or self.zf
        elif (index == 0x4): # S
            ret = self.sf
        elif (index == 0x5): # P
            ret = self.pf
        elif (index == 0x6): # L
            ret = self.sf != self.of
        elif (index == 0x7): # LE
            ret = self.zf or self.sf != self.of
        #else:
        #    self.main.exitError("getCond: index {0:#04x} is invalid.", index)
        if (negateCheck):
            ret = not ret
        return ret
    cdef inline void setFullFlags(self, unsigned long int reg0, unsigned long int reg1, unsigned char regSize, unsigned char method) nogil:
        cdef unsigned char unsignedOverflow, reg0Nibble, regSumuNibble, carried
        cdef unsigned int bitMaskHalf
        cdef unsigned long int regSumu
        cdef signed long int regSum
        carried = False
        bitMaskHalf = BITMASKS_80[regSize]
        if (method in (OPCODE_ADD, OPCODE_ADC)):
            if (method == OPCODE_ADC and self.cf):
                carried = True
            if (regSize == OP_SIZE_BYTE):
                reg0 = <unsigned char>reg0
                reg1 = <unsigned char>reg1
                if (carried): reg1 += 1
                regSumu = (reg0+reg1)
                unsignedOverflow = regSumu!=(<unsigned char>regSumu)
                regSumu = <unsigned char>regSumu
            elif (regSize == OP_SIZE_WORD):
                reg0 = <unsigned short>reg0
                reg1 = <unsigned short>reg1
                if (carried): reg1 += 1
                regSumu = (reg0+reg1)
                unsignedOverflow = regSumu!=(<unsigned short>regSumu)
                regSumu = <unsigned short>regSumu
            elif (regSize == OP_SIZE_DWORD):
                reg0 = <unsigned int>reg0
                reg1 = <unsigned int>reg1
                if (carried): reg1 += 1
                regSumu = (reg0+reg1)
                unsignedOverflow = regSumu!=(<unsigned int>regSumu)
                regSumu = <unsigned int>regSumu
            self.pf = PARITY_TABLE[<unsigned char>regSumu]
            self.zf = not regSumu
            reg0Nibble = reg0&0xf
            regSumuNibble = regSumu&0xf
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSumu &= bitMaskHalf
            self.af = (regSumuNibble<(reg0Nibble+carried))
            self.cf = unsignedOverflow
            self.of = (reg0==reg1 and reg0!=regSumu)
            self.sf = regSumu!=0
        elif (method in (OPCODE_SUB, OPCODE_SBB)):
            if (method == OPCODE_SBB and self.cf):
                carried = True
                reg1 += 1
            regSumu = <unsigned int>(reg0-reg1)
            if (regSize == OP_SIZE_BYTE):
                regSumu = <unsigned char>regSumu
            elif (regSize == OP_SIZE_WORD):
                regSumu = <unsigned short>regSumu
            unsignedOverflow = ((regSumu+carried) > reg0)
            self.pf = PARITY_TABLE[<unsigned char>regSumu]
            self.zf = not regSumu
            reg0Nibble = reg0&0xf
            regSumuNibble = regSumu&0xf
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSumu &= bitMaskHalf
            self.af = ((regSumuNibble+carried)>reg0Nibble)
            self.cf = unsignedOverflow
            self.of = (reg0!=reg1 and reg1==regSumu)
            self.sf = regSumu!=0
        elif (method in (OPCODE_MUL, OPCODE_IMUL)):
            if (regSize == OP_SIZE_BYTE):
                reg1 = <unsigned char>reg1
                if (method == OPCODE_MUL):
                    reg0 = <unsigned char>reg0
                    regSumu = (reg0*reg1)
                    unsignedOverflow = (<unsigned short>regSumu)!=(<unsigned char>regSumu)
                else:
                    reg0 = <signed char>reg0
                    regSumu = regSum = (reg0*reg1)
                    unsignedOverflow = (<signed short>regSum)!=(<signed char>regSum)
                regSumu = <unsigned char>regSumu
            elif (regSize == OP_SIZE_WORD):
                reg1 = <unsigned short>reg1
                if (method == OPCODE_MUL):
                    reg0 = <unsigned short>reg0
                    regSumu = (reg0*reg1)
                    unsignedOverflow = (<unsigned int>regSumu)!=(<unsigned short>regSumu)
                else:
                    reg0 = <signed short>reg0
                    regSumu = regSum = (reg0*reg1)
                    unsignedOverflow = (<signed int>regSum)!=(<signed short>regSum)
                regSumu = <unsigned short>regSumu
            elif (regSize == OP_SIZE_DWORD):
                reg1 = <unsigned int>reg1
                if (method == OPCODE_MUL):
                    reg0 = <unsigned int>reg0
                    regSumu = (reg0*reg1)
                    unsignedOverflow = (<unsigned long int>regSumu)!=(<unsigned int>regSumu)
                else:
                    reg0 = <signed int>reg0
                    regSumu = regSum = (reg0*reg1)
                    unsignedOverflow = (<signed long int>regSum)!=(<signed int>regSum)
                regSumu = <unsigned int>regSumu
            self.af = False
            self.cf = self.of = unsignedOverflow
            self.pf = PARITY_TABLE[<unsigned char>regSumu]
            self.zf = not regSumu
            self.sf = (regSumu & bitMaskHalf) != 0
    cdef inline unsigned char checkMemAccessRights(self, unsigned int mmAddr, unsigned int dataSize, Segment segment, unsigned char written) nogil except BITMASK_BYTE_CONST:
        cdef unsigned char addrInLimit
        cdef unsigned short segId, segVal
        segId = segment.segId
        segVal = segment.segmentIndex
        addrInLimit = segment.isAddressInLimit(mmAddr, dataSize)
        if (not addrInLimit):
            with gil:
                if (segId == CPU_SEGMENT_SS):
                    raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                else:
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
        if ((written and segment.writeChecked) or (not written and segment.readChecked)):
            return True
        if (segment.useGDT):
            if (not (segVal&0xfff8)):
                with gil:
                    #self.main.notice("Registers::checkMemAccessRights: test1.1")
                    if (segId == CPU_SEGMENT_SS):
                        raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                    else:
                        raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
            if (not segment.segPresent):
                with gil:
                    #self.main.notice("Registers::checkMemAccessRights: test1.2")
                    if (segId == CPU_SEGMENT_SS):
                        raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                    else:
                        raise HirnwichseException(CPU_EXCEPTION_NP, segVal)
        if (written):
            if (segment.useGDT and segment.segIsNormal and (segment.segIsCodeSeg or not segment.segIsRW)):
                with gil:
                    #self.main.notice("Registers::checkMemAccessRights: test1.3")
                    #self.main.notice("Registers::checkMemAccessRights: test1.3.1; c0=={0:d}; c1=={1:d}; c2=={2:d}", segment.segIsNormal, (segment.segIsCodeSeg or not segment.segIsRW), not addrInLimit)
                    #self.main.notice("Registers::checkMemAccessRights: test1.3.2; mmAddr=={0:#010x}; dataSize=={1:d}; base=={2:#010x}; limit=={3:#010x}", mmAddr, dataSize, segment.base, segment.limit)
                    if (segId == CPU_SEGMENT_SS):
                        raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                    else:
                        raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
            segment.writeChecked = True
        else:
            if (segment.useGDT and segment.segIsNormal and segment.segIsCodeSeg and not segment.segIsRW):
                with gil:
                    #self.main.notice("Registers::checkMemAccessRights: test1.4")
                    if (segId == CPU_SEGMENT_SS):
                        raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                    else:
                        raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
            segment.readChecked = True
        return True
    cdef inline unsigned int mmGetRealAddr(self, unsigned int mmAddr, unsigned int dataSize, Segment segment, unsigned char allowOverride, unsigned char written) nogil except? BITMASK_BYTE_CONST:
        cdef PyObject *segment2
        cdef unsigned int origMmAddr
        origMmAddr = mmAddr
        if (allowOverride and self.segmentOverridePrefix is not NULL):
            segment2 = <PyObject*>self.segmentOverridePrefix
        else:
            segment2 = <PyObject*>segment
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmGetRealAddr_1: {0:s}: LIN {1:#010x}; dataSize {2:d}; segId {3:d}", "WR" if (written) else "RD", origMmAddr, dataSize, (<Segment>segment2).segId)
        if (<Segment>segment2 is not None):
            if (self.protectedModeOn and <Segment>segment2 is (<Segment>self.segments.tss)):
                (<Paging>(<Segments>self.segments).paging).implicitSV = True
            #if (segment2.useGDT):
            self.checkMemAccessRights(mmAddr, dataSize, <Segment>segment2, written)
            mmAddr += (<Segment>segment2).base
        # TODO: check for limit asf...
        if (self.protectedModeOn and self.pagingOn): # TODO: is a20 even being applied after paging is enabled? (on the physical address... or even the virtual one?)
            mmAddr = (<Paging>(<Segments>self.segments).paging).getPhysicalAddress(mmAddr, dataSize, written)
        if (not self.A20Active): # A20 Active? if True == on, else off
            mmAddr &= <unsigned int>0xffefffff
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmGetRealAddr_2: {0:s}: LIN {1:#010x}; PHY {2:#010x}", "WR" if (written) else "RD", origMmAddr, mmAddr)
        return mmAddr
    cdef signed long int mmReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize, Segment segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST:
        cdef unsigned char i
        cdef unsigned int physAddr
        cdef signed long int ret = 0
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, False)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
            for i in range(dataSize):
                ret |= <signed long int>self.mmReadValueUnsignedByte(mmAddr+i, segment, allowOverride)<<(i<<3)
            if (dataSize == OP_SIZE_BYTE):
                return <signed char>ret
            elif (dataSize == OP_SIZE_WORD):
                return <signed short>ret
            elif (dataSize == OP_SIZE_DWORD):
                return <signed int>ret
            return <signed long int>ret
        ret = self.main.mm.mmPhyReadValueSigned(physAddr, dataSize)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmReadValueSigned: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, dataSize)
        return ret
    cdef inline unsigned char mmReadValueUnsignedByte(self, unsigned int mmAddr, Segment segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST:
        cdef unsigned char ret
        #if (self.main.debugEnabled):
        #    with gil:
        #        self.main.notice("Registers::mmReadValueUnsignedByte_1: virt mmAddr {0:#010x}; dataSize {1:d}", mmAddr, OP_SIZE_BYTE)
        ret = self.main.mm.mmPhyReadValueUnsignedByte(self.mmGetRealAddr(mmAddr, OP_SIZE_BYTE, segment, allowOverride, False))
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmReadValueUnsignedByte_2: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, OP_SIZE_BYTE)
        return ret
    cdef unsigned short mmReadValueUnsignedWord(self, unsigned int mmAddr, Segment segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST:
        cdef unsigned short ret
        cdef unsigned int physAddr
        physAddr = self.mmGetRealAddr(mmAddr, OP_SIZE_WORD, segment, allowOverride, False)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_WORD):
            ret = <unsigned short>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
            ret |= <unsigned short>self.mmReadValueUnsignedByte(mmAddr+1, segment, allowOverride)<<8
            return ret
        ret = self.main.mm.mmPhyReadValueUnsignedWord(physAddr)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmReadValueUnsignedWord: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, OP_SIZE_WORD)
        return ret
    cdef unsigned int mmReadValueUnsignedDword(self, unsigned int mmAddr, Segment segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST:
        cdef unsigned int ret, physAddr
        physAddr = self.mmGetRealAddr(mmAddr, OP_SIZE_DWORD, segment, allowOverride, False)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_DWORD):
            ret = <unsigned int>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
            ret |= <unsigned int>self.mmReadValueUnsignedByte(mmAddr+1, segment, allowOverride)<<8
            ret |= <unsigned int>self.mmReadValueUnsignedByte(mmAddr+2, segment, allowOverride)<<16
            ret |= <unsigned int>self.mmReadValueUnsignedByte(mmAddr+3, segment, allowOverride)<<24
            return ret
        ret = self.main.mm.mmPhyReadValueUnsignedDword(physAddr)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmReadValueUnsignedDword: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, OP_SIZE_DWORD)
        return ret
    cdef unsigned long int mmReadValueUnsignedQword(self, unsigned int mmAddr, Segment segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST:
        cdef unsigned int physAddr
        cdef unsigned long int ret
        physAddr = self.mmGetRealAddr(mmAddr, OP_SIZE_QWORD, segment, allowOverride, False)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < OP_SIZE_QWORD):
            ret = <unsigned long int>self.mmReadValueUnsignedByte(mmAddr, segment, allowOverride)
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+1, segment, allowOverride)<<8
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+2, segment, allowOverride)<<16
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+3, segment, allowOverride)<<24
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+4, segment, allowOverride)<<32
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+5, segment, allowOverride)<<40
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+6, segment, allowOverride)<<48
            ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+7, segment, allowOverride)<<56
            return ret
        ret = self.main.mm.mmPhyReadValueUnsignedQword(physAddr)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmReadValueUnsignedQword: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, OP_SIZE_QWORD)
        return ret
    cdef unsigned long int mmReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize, Segment segment, unsigned char allowOverride) nogil except? BITMASK_BYTE_CONST:
        cdef unsigned char i
        cdef unsigned int physAddr
        cdef unsigned long int ret = 0
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, False)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
            for i in range(dataSize):
                ret |= <unsigned long int>self.mmReadValueUnsignedByte(mmAddr+i, segment, allowOverride)<<(i<<3)
            return ret
        ret = self.main.mm.mmPhyReadValueUnsigned(physAddr, dataSize)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmReadValueUnsigned: virt mmAddr {0:#010x}; ret {1:#010x}; dataSize {2:d}", mmAddr, ret, dataSize)
        return ret
    cdef unsigned char mmWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize, Segment segment, unsigned char allowOverride) nogil except BITMASK_BYTE_CONST:
        cdef unsigned char retVal, i
        cdef unsigned int physAddr
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmWriteValue: virt mmAddr {0:#010x}; data {1:#010x}; dataSize {2:d}", mmAddr, data, dataSize)
        physAddr = self.mmGetRealAddr(mmAddr, dataSize, segment, allowOverride, True)
        if (self.protectedModeOn and self.pagingOn and PAGE_DIRECTORY_LENGTH-(physAddr&0xfff) < dataSize):
            for i in range(dataSize):
                self.mmWriteValue(mmAddr+i, <unsigned char>data, OP_SIZE_BYTE, segment, allowOverride)
                data >>= 8
            return True
        retVal = self.main.mm.mmPhyWriteValue(physAddr, data, dataSize)
        IF CPU_CACHE_SIZE:
            self.checkCache(mmAddr, dataSize)
        return retVal
    cdef unsigned long int mmWriteValueWithOp(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize, Segment segment, unsigned char allowOverride, unsigned char valueOp) nogil except? BITMASK_BYTE_CONST:
        cdef unsigned long int oldData
        if (valueOp != OPCODE_SAVE):
            if (valueOp == OPCODE_NEG):
                data = (-data)
            elif (valueOp == OPCODE_NOT):
                data = (~data)
            else:
                oldData = self.mmReadValueUnsigned(mmAddr, dataSize, segment, allowOverride)
                if (valueOp == OPCODE_ADD):
                    data = (oldData+data)
                elif (valueOp in (OPCODE_ADC, OPCODE_SBB)):
                    data += self.cf
                    if (valueOp == OPCODE_ADC):
                        data = (oldData+data)
                    else:
                        data = (oldData-data)
                elif (valueOp == OPCODE_SUB):
                    data = (oldData-data)
                elif (valueOp == OPCODE_AND):
                    data = (oldData&data)
                elif (valueOp == OPCODE_OR):
                    data = (oldData|data)
                elif (valueOp == OPCODE_XOR):
                    data = (oldData^data)
                #else:
                #    self.main.exitError("Registers::mmWriteValueWithOp: unknown valueOp {0:d}.", valueOp)
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("Registers::mmWriteValueWithOp: virt mmAddr {0:#010x}; data {1:#010x}; dataSize {2:d}", mmAddr, data, dataSize)
        self.mmWriteValue(mmAddr, data, dataSize, segment, allowOverride)
        return data
    cdef unsigned char switchTSS16(self) except BITMASK_BYTE_CONST:
        cdef unsigned int baseAddress
        cdef GdtEntry gdtEntry
        self.main.notice("Registers::switchTSS16: TODO? (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        baseAddress = self.mmGetRealAddr(0, 1, (<Segment>self.segments.tss), False, False)
        if (((baseAddress&0xfff)+TSS_MIN_16BIT_HARD_LIMIT) > 0xfff):
            self.main.exitError("Registers::switchTSS16: TSS is over page boundary!")
            return False
        self.segments.ldtr = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_LDT_SEG_SEL)
        if (self.segments.ldtr):
            gdtEntry = <GdtEntry>self.segments.gdt.getEntry(self.segments.ldtr&0xfff8)
            if (gdtEntry is None):
                self.main.notice("Registers::switchTSS16: gdtEntry is invalid, mark LDTR as invalid.")
                (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
            else:
                (<Gdt>self.segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
        else:
            (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
        self.segWriteSegment((<Segment>self.segments.cs), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_CS))
        self.regWriteWord(CPU_REGISTER_IP, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_IP))
        self.segWriteSegment((<Segment>self.segments.ss), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_SS))
        self.regWriteWord(CPU_REGISTER_SP, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_SP))
        if (self.regWriteWordFlags(self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_FLAGS))):
            self.main.cpu.asyncEvent = True
        self.segWriteSegment((<Segment>self.segments.ds), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_DS))
        self.segWriteSegment((<Segment>self.segments.es), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_ES))
        self.regWriteWord(CPU_REGISTER_AX, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_AX))
        self.regWriteWord(CPU_REGISTER_CX, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_CX))
        self.regWriteWord(CPU_REGISTER_DX, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_DX))
        self.regWriteWord(CPU_REGISTER_BX, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_BX))
        self.regWriteWord(CPU_REGISTER_BP, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_BP))
        self.regWriteWord(CPU_REGISTER_SI, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_SI))
        self.regWriteWord(CPU_REGISTER_DI, self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_16BIT_DI))

        self.regOrDword(CPU_REGISTER_CR0, CR0_FLAG_TS)
        return True
    cdef unsigned char saveTSS16(self) except BITMASK_BYTE_CONST:
        cdef unsigned int baseAddress
        self.main.notice("Registers::saveTSS16: TODO? (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        baseAddress = self.mmGetRealAddr(0, 1, (<Segment>self.segments.tss), False, True)
        if (((baseAddress&0xfff)+TSS_MIN_16BIT_HARD_LIMIT) > 0xfff):
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
    cdef unsigned char switchTSS32(self) except BITMASK_BYTE_CONST:
        cdef unsigned int baseAddress, temp
        cdef GdtEntry gdtEntry
        self.main.notice("Registers::switchTSS32: TODO? (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        self.main.cpu.cpuDump()
        self.main.notice("Registers::switchTSS32: TODO? (getCPL(): {0:d}; cpl: {1:d})", self.getCPL(), self.cpl)
        baseAddress = self.mmGetRealAddr(0, 1, (<Segment>self.segments.tss), False, False)
        if (((baseAddress&0xfff)+TSS_MIN_32BIT_HARD_LIMIT) > 0xfff):
            self.main.exitError("Registers::switchTSS32: TSS is over page boundary!")
            return False
        if (self.protectedModeOn and self.pagingOn):
            temp = self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_CR3)
            self.regWriteDword(CPU_REGISTER_CR3, temp)
            #(<Paging>self.segments.paging).invalidateTables(temp, True)
            (<Paging>self.segments.paging).invalidateTables(temp, False)
            IF (CPU_CACHE_SIZE):
                self.reloadCpuCache()
        self.segments.ldtr = self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_LDT_SEG_SEL)
        if (self.segments.ldtr):
            gdtEntry = <GdtEntry>self.segments.gdt.getEntry(self.segments.ldtr&0xfff8)
            if (gdtEntry is None):
                self.main.notice("Registers::switchTSS32: gdtEntry is invalid, mark LDTR as invalid.")
                (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
            else:
                (<Gdt>self.segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
        else:
            (<Gdt>self.segments.ldt).loadTablePosition(0, 0)
        self.segWriteSegment((<Segment>self.segments.cs), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_CS))
        self.regWriteDword(CPU_REGISTER_EIP, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EIP))
        self.segWriteSegment((<Segment>self.segments.ss), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_SS))
        self.regWriteDword(CPU_REGISTER_ESP, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_ESP))
        if (self.regWriteDwordEflags(self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EFLAGS))):
            self.main.cpu.asyncEvent = True
        self.segWriteSegment((<Segment>self.segments.ds), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_DS))
        self.segWriteSegment((<Segment>self.segments.es), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_ES))
        self.segWriteSegment((<Segment>self.segments.fs), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_FS))
        self.segWriteSegment((<Segment>self.segments.gs), self.main.mm.mmPhyReadValueUnsignedWord(baseAddress + TSS_32BIT_GS))
        self.regWriteDword(CPU_REGISTER_EAX, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EAX))
        self.regWriteDword(CPU_REGISTER_ECX, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_ECX))
        self.regWriteDword(CPU_REGISTER_EDX, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EDX))
        self.regWriteDword(CPU_REGISTER_EBX, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EBX))
        self.regWriteDword(CPU_REGISTER_EBP, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EBP))
        self.regWriteDword(CPU_REGISTER_ESI, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_ESI))
        self.regWriteDword(CPU_REGISTER_EDI, self.main.mm.mmPhyReadValueUnsignedDword(baseAddress + TSS_32BIT_EDI))

        self.regOrDword(CPU_REGISTER_CR0, CR0_FLAG_TS)
        self.main.cpu.cpuDump()
        self.main.notice("Registers::switchTSS32: TODO? (getCPL(): {0:d}; cpl: {1:d})", self.getCPL(), self.cpl)
        if ((self.main.mm.mmPhyReadValueUnsignedByte(baseAddress + TSS_32BIT_T_FLAG) & 1) != 0):
            self.main.notice("Registers::switchTSS32: Debug")
            raise HirnwichseException(CPU_EXCEPTION_DB)
        return True
    cdef unsigned char saveTSS32(self) except BITMASK_BYTE_CONST:
        cdef unsigned int baseAddress
        self.main.notice("Registers::saveTSS32: TODO? (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        self.main.cpu.cpuDump()
        self.main.notice("Registers::saveTSS32: TODO? (getCPL(): {0:d}; cpl: {1:d})", self.getCPL(), self.cpl)
        baseAddress = self.mmGetRealAddr(0, 1, (<Segment>self.segments.tss), False, True)
        if (((baseAddress&0xfff)+TSS_MIN_32BIT_HARD_LIMIT) > 0xfff):
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


