
from misc import HirnwichseException

include "globals.pxi"
include "cpu_globals.pxi"


# Parity Flag Table: DO NOT EDIT!!!
DEF PARITY_TABLE = (True, False, False, True, False, True, True, False, False, True,
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
    def __init__(self, object main, Registers registers):
        self.main = main
        self.registers = registers
    cdef unsigned short modRMOperands(self, unsigned char regSize, unsigned char modRMflags): # regSize in bytes
        cdef unsigned char modRMByte, index
        modRMByte = self.registers.getCurrentOpcodeAddUnsignedByte()
        self.rmNameSegId = CPU_SEGMENT_DS
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
            if (self.registers.addrSize == OP_SIZE_WORD):
                self.rmName0 = CPU_MODRM_16BIT_RM0[self.rm]
                self.rmName1 = CPU_MODRM_16BIT_RM1[self.rm]
                if (self.mod == 0 and self.rm == 6):
                    self.rmName0 = CPU_REGISTER_NONE
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedWord()
                elif (self.mod == 1):
                    self.rmName2 = self.registers.getCurrentOpcodeAddSignedByte()
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedWord()
                if (self.rmName0 == CPU_REGISTER_BP): # TODO: damn, that can't be correct!?!
                    self.rmNameSegId = CPU_SEGMENT_SS
            elif (self.registers.addrSize == OP_SIZE_DWORD):
                if (self.rm == 4): # If RM==4; then SIB
                    modRMByte = self.registers.getCurrentOpcodeAddUnsignedByte()
                    self.rm  = modRMByte&0x7
                    index   = (modRMByte>>3)&7
                    self.ss = (modRMByte>>6)&3
                    if (index != 4):
                        self.rmName1 = index
                    if (self.rm == CPU_REGISTER_ESP):
                        self.rmNameSegId = CPU_SEGMENT_SS
                if (self.mod == 0 and self.rm == 5):
                    self.rmName0 = CPU_REGISTER_NONE
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedDword()
                else:
                    self.rmName0 = self.rm
                    if (self.rmName0 == CPU_REGISTER_EBP):
                        self.rmNameSegId = CPU_SEGMENT_SS
                if (self.mod == 1):
                    self.rmName2 = self.registers.getCurrentOpcodeAddSignedByte()
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsignedDword()
            self.rmNameSegId = self.registers.segmentOverridePrefix or self.rmNameSegId
        return True
    cdef unsigned long int getRMValueFull(self, unsigned char rmSize):
        cdef unsigned long int retAddr
        if (self.regSize in (OP_SIZE_BYTE, OP_SIZE_WORD)):
            retAddr = <unsigned short>(self.registers.regReadUnsignedWord(self.rmName0))
            if (self.regSize == OP_SIZE_BYTE):
                if (self.rm >= 4):
                    retAddr >>= 8
                retAddr = <unsigned char>retAddr
        elif (self.regSize == OP_SIZE_DWORD):
            retAddr = <unsigned int>(self.registers.regReadUnsignedDword(self.rmName0))
        elif (self.regSize == OP_SIZE_QWORD):
            retAddr = <unsigned long int>(self.registers.regReadUnsignedQword(self.rmName0))
        if (self.rmName1 != CPU_REGISTER_NONE):
            retAddr = <unsigned long int>(retAddr+(self.registers.regReadUnsigned(self.rmName1, self.registers.addrSize)<<self.ss))
        retAddr = <unsigned long int>(retAddr+self.rmName2)
        if (rmSize == OP_SIZE_BYTE):
            return <unsigned char>retAddr
        elif (rmSize == OP_SIZE_WORD):
            return <unsigned short>retAddr
        elif (rmSize == OP_SIZE_DWORD):
            return <unsigned int>retAddr
        #elif (rmSize == OP_SIZE_QWORD):
        #    return <unsigned long int>retAddr
        return retAddr
    cdef signed long int modRMLoadSigned(self, unsigned char regSize, unsigned char allowOverride):
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
            mmAddr = self.getRMValueFull(self.registers.addrSize)
            returnInt = self.registers.mmReadValueSigned(mmAddr, regSize, self.rmNameSegId, allowOverride)
        return returnInt
    cdef unsigned long int modRMLoadUnsigned(self, unsigned char regSize, unsigned char allowOverride):
        # NOTE: imm == unsigned ; disp == signed
        cdef unsigned long int mmAddr, returnInt
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
            mmAddr = self.getRMValueFull(self.registers.addrSize)
            returnInt = self.registers.mmReadValueUnsigned(mmAddr, regSize, self.rmNameSegId, allowOverride)
        return returnInt
    cdef unsigned long int modRMSave(self, unsigned char regSize, unsigned long int value, unsigned char allowOverride, unsigned char valueOp):
        # stdAllowOverride==True, stdValueOp==OPCODE_SAVE
        cdef unsigned long int mmAddr
        if (self.mod != 3):
            mmAddr = self.getRMValueFull(self.registers.addrSize)
        if (regSize == OP_SIZE_BYTE):
            if (self.mod == 3):
                if (self.rm <= 3):
                    return self.registers.regWriteWithOpLowByte(self.rmName0, <unsigned char>value, valueOp)
                else: # self.rm >= 4
                    return self.registers.regWriteWithOpHighByte(self.rmName0, <unsigned char>value, valueOp)
            return <unsigned char>(self.registers.mmWriteValueWithOpSize(mmAddr, <unsigned char>value, self.rmNameSegId, allowOverride, valueOp))
        elif (regSize == OP_SIZE_WORD):
            if (self.mod == 3):
                return self.registers.regWriteWithOpWord(self.rmName0, <unsigned short>value, valueOp)
            return <unsigned short>(self.registers.mmWriteValueWithOpSize(mmAddr, <unsigned short>value, self.rmNameSegId, allowOverride, valueOp))
        elif (regSize == OP_SIZE_DWORD):
            if (self.mod == 3):
                return self.registers.regWriteWithOpDword(self.rmName0, <unsigned int>value, valueOp)
            return <unsigned int>(self.registers.mmWriteValueWithOpSize(mmAddr, <unsigned int>value, self.rmNameSegId, allowOverride, valueOp))
        elif (regSize == OP_SIZE_QWORD):
            if (self.mod == 3):
                return self.registers.regWriteWithOpQword(self.rmName0, <unsigned long int>value, valueOp)
            return <unsigned long int>(self.registers.mmWriteValueWithOpSize(mmAddr, <unsigned long int>value, self.rmNameSegId, allowOverride, valueOp))
        self.main.exitError("ModRMClass::modRMSave: if; else.")
        return 0
    cdef signed long int modRLoadSigned(self, unsigned char regSize):
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
    cdef unsigned long int modRLoadUnsigned(self, unsigned char regSize):
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
    cdef unsigned long int modRSave(self, unsigned char regSize, unsigned long int value, unsigned char valueOp):
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
            value = <unsigned long int>value
            return self.registers.regWriteWithOpQword(self.regName, value, valueOp)



cdef class Registers:
    def __init__(self, object main):
        self.registers = self
        self.main = main
    cdef void reset(self):
        self.operSize = self.addrSize = self.cf = self.pf = self.af = self.zf = self.sf = self.tf = \
          self.if_flag = self.df = self.of = self.iopl = self.nt = self.rf = self.vm = self.ac = \
          self.vif = self.vip = self.id = 0
        self.resetPrefixes()
        self.segments.reset()
        self.regWriteDword(CPU_REGISTER_EFLAGS, FLAG_REQUIRED)
        #self.regWriteDword(CPU_REGISTER_CR0, 0x40000014)
        self.regWriteDword(CPU_REGISTER_CR0, 0x60000010)
        self.segWrite(CPU_SEGMENT_CS, 0xf000)
        self.regWriteDword(CPU_REGISTER_EIP, 0xfff0)
    cdef void resetPrefixes(self):
        self.operandSizePrefix = self.addressSizePrefix = self.segmentOverridePrefix = self.repPrefix = 0
    cdef unsigned int readFlags(self):
        return (FLAG_REQUIRED | self.cf | (self.pf<<2) | (self.af<<4) | (self.zf<<6) | (self.sf<<7) | (self.tf<<8) | (self.if_flag<<9) | (self.df<<10) | \
          (self.of<<11) | (self.iopl<<12) | (self.nt<<14) | (self.rf<<16) | (self.vm<<17) | (self.ac<<18) | (self.vif<<19) | (self.vip<<20) | (self.id<<21))
    cdef void setFlags(self, unsigned int flags):
        self.cf = (flags&FLAG_CF)!=0
        self.pf = (flags&FLAG_PF)!=0
        self.af = (flags&FLAG_AF)!=0
        self.zf = (flags&FLAG_ZF)!=0
        self.sf = (flags&FLAG_SF)!=0
        self.tf = (flags&FLAG_TF)!=0
        self.if_flag = (flags&FLAG_IF)!=0
        self.df = (flags&FLAG_DF)!=0
        self.of = (flags&FLAG_OF)!=0
        self.iopl = (flags>>12)&3
        self.nt = (flags&FLAG_NT)!=0
        self.rf = (flags&FLAG_RF)!=0
        self.vm = (flags&FLAG_VM)!=0
        self.ac = (flags&FLAG_AC)!=0
        self.vif = (flags&FLAG_VIF)!=0
        self.vip = (flags&FLAG_VIP)!=0
        self.id = (flags&FLAG_ID)!=0
    cdef unsigned char getCPL(self):
        if (not (<Segments>self.segments).isInProtectedMode()):
            return 0
        return ((<Segment>self.segments.cs).segmentIndex&3)
    cdef unsigned char getIOPL(self):
        return self.iopl
    cdef signed char getCurrentOpcodeSignedByte(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        return self.mmReadValueSignedByte(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef signed short getCurrentOpcodeSignedWord(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        return self.mmReadValueSignedWord(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef signed int getCurrentOpcodeSignedDword(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        return self.mmReadValueSignedDword(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef signed long int getCurrentOpcodeSignedQword(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        return self.mmReadValueSignedQword(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef signed long int getCurrentOpcodeSigned(self, unsigned char numBytes):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        return self.mmReadValueSigned(opcodeAddr, numBytes, CPU_SEGMENT_CS, False)
    cdef unsigned char getCurrentOpcodeUnsignedByte(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        return self.mmReadValueUnsignedByte(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef unsigned short getCurrentOpcodeUnsignedWord(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        return self.mmReadValueUnsignedWord(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef unsigned int getCurrentOpcodeUnsignedDword(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        return self.mmReadValueUnsignedDword(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef unsigned long int getCurrentOpcodeUnsignedQword(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        return self.mmReadValueUnsignedQword(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef unsigned long int getCurrentOpcodeUnsigned(self, unsigned char numBytes):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        return self.mmReadValueUnsigned(opcodeAddr, numBytes, CPU_SEGMENT_CS, False)
    cdef signed char getCurrentOpcodeAddSignedByte(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.regWriteDword(CPU_REGISTER_EIP, <unsigned int>(opcodeAddr+OP_SIZE_BYTE))
        return self.mmReadValueSignedByte(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef signed short getCurrentOpcodeAddSignedWord(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.regWriteDword(CPU_REGISTER_EIP, <unsigned int>(opcodeAddr+OP_SIZE_WORD))
        return self.mmReadValueSignedWord(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef signed int getCurrentOpcodeAddSignedDword(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.regWriteDword(CPU_REGISTER_EIP, <unsigned int>(opcodeAddr+OP_SIZE_DWORD))
        return self.mmReadValueSignedDword(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef signed long int getCurrentOpcodeAddSignedQword(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.regWriteDword(CPU_REGISTER_EIP, <unsigned int>(opcodeAddr+OP_SIZE_QWORD))
        return self.mmReadValueSignedQword(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef signed long int getCurrentOpcodeAddSigned(self, unsigned char numBytes):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.regWriteDword(CPU_REGISTER_EIP, <unsigned int>(opcodeAddr+numBytes))
        return self.mmReadValueSigned(opcodeAddr, numBytes, CPU_SEGMENT_CS, False)
    cdef unsigned char getCurrentOpcodeAddUnsignedByte(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.regWriteDword(CPU_REGISTER_EIP, <unsigned int>(opcodeAddr+OP_SIZE_BYTE))
        return self.mmReadValueUnsignedByte(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef unsigned short getCurrentOpcodeAddUnsignedWord(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.regWriteDword(CPU_REGISTER_EIP, <unsigned int>(opcodeAddr+OP_SIZE_WORD))
        return self.mmReadValueUnsignedWord(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef unsigned int getCurrentOpcodeAddUnsignedDword(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.regWriteDword(CPU_REGISTER_EIP, <unsigned int>(opcodeAddr+OP_SIZE_DWORD))
        return self.mmReadValueUnsignedDword(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef unsigned long int getCurrentOpcodeAddUnsignedQword(self):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.regWriteDword(CPU_REGISTER_EIP, <unsigned int>(opcodeAddr+OP_SIZE_QWORD))
        return self.mmReadValueUnsignedQword(opcodeAddr, CPU_SEGMENT_CS, False)
    cdef unsigned long int getCurrentOpcodeAddUnsigned(self, unsigned char numBytes):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.regWriteDword(CPU_REGISTER_EIP, <unsigned int>(opcodeAddr+numBytes))
        return self.mmReadValueUnsigned(opcodeAddr, numBytes, CPU_SEGMENT_CS, False)
    cdef unsigned char getCurrentOpcodeAddWithAddr(self, unsigned short *retSeg, unsigned int *retAddr):
        retSeg[0]  = self.segRead(CPU_SEGMENT_CS)
        retAddr[0] = self.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.regWriteDword(CPU_REGISTER_EIP, <unsigned int>(retAddr[0]+OP_SIZE_BYTE))
        return self.mmReadValueUnsignedByte(retAddr[0], CPU_SEGMENT_CS, False)
    cdef unsigned short segRead(self, unsigned short segId):
        IF STRICT_CHECKS:
            if (not segId or (segId not in CPU_REGISTER_SREG)):
                self.main.exitError("segRead: segId is not a segment! ({0:d})", segId)
                return 0
        return self.regs[CPU_SEGMENT_BASE+segId]._union.word._union.rx
    cdef unsigned short segWrite(self, unsigned short segId, unsigned short segValue):
        cdef Segment segmentInstance
        IF STRICT_CHECKS:
            if (not segId or (segId not in CPU_REGISTER_SREG)):
                self.main.exitError("segWrite: segId is not a segment! ({0:d})", segId)
                return 0
        segmentInstance = self.segments.getSegmentInstance(segId, False)
        segmentInstance.loadSegment(segValue)
        if ((<Segments>self.segments).isInProtectedMode()):
            if (not (<Segments>self.segments).checkSegmentLoadAllowed(segValue, segId)):
                segmentInstance.isValid = False
        if (segId == CPU_SEGMENT_CS):
            self.codeSegSize = segmentInstance.getSegSize()
        self.regs[CPU_SEGMENT_BASE+segId]._union.word._union.rx = segValue
        return segValue
    cdef signed long int regReadSigned(self, unsigned short regId, unsigned char regSize):
        if (regSize == OP_SIZE_BYTE):
            return self.regReadSignedLowByte(regId)
        elif (regSize == OP_SIZE_WORD):
            return self.regReadSignedWord(regId)
        elif (regSize == OP_SIZE_DWORD):
            return self.regReadSignedDword(regId)
        elif (regSize == OP_SIZE_QWORD):
            return self.regReadSignedQword(regId)
        return 0
    cdef unsigned long int regReadUnsigned(self, unsigned short regId, unsigned char regSize):
        if (regSize == OP_SIZE_BYTE):
            return self.regReadUnsignedLowByte(regId)
        elif (regSize == OP_SIZE_WORD):
            return self.regReadUnsignedWord(regId)
        elif (regSize == OP_SIZE_DWORD):
            return self.regReadUnsignedDword(regId)
        elif (regSize == OP_SIZE_QWORD):
            return self.regReadUnsignedQword(regId)
        return 0
    cdef unsigned long int regWrite(self, unsigned short regId, unsigned long int value, unsigned char regSize):
        if (regSize == OP_SIZE_BYTE):
            return self.regWriteLowByte(regId, value)
        elif (regSize == OP_SIZE_WORD):
            return self.regWriteWord(regId, value)
        elif (regSize == OP_SIZE_DWORD):
            return self.regWriteDword(regId, value)
        elif (regSize == OP_SIZE_QWORD):
            return self.regWriteQword(regId, value)
        return 0
    cdef unsigned long int regAdd(self, unsigned short regId, unsigned long int value, unsigned char regSize):
        if (regSize == OP_SIZE_WORD):
            return self.regAddWord(regId, value)
        elif (regSize == OP_SIZE_DWORD):
            return self.regAddDword(regId, value)
        elif (regSize == OP_SIZE_QWORD):
            return self.regAddQword(regId, value)
        return 0
    cdef unsigned long int regSub(self, unsigned short regId, unsigned long int value, unsigned char regSize):
        if (regSize == OP_SIZE_WORD):
            return self.regSubWord(regId, value)
        elif (regSize == OP_SIZE_DWORD):
            return self.regSubDword(regId, value)
        elif (regSize == OP_SIZE_QWORD):
            return self.regSubQword(regId, value)
        return 0
    cdef unsigned char regWriteWithOpLowByte(self, unsigned short regId, unsigned char value, unsigned char valueOp):
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
            value = <unsigned char>(-value)
            return self.regWriteLowByte(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = <unsigned char>(~value)
            return self.regWriteLowByte(regId, value)
        else:
            self.main.notice("REGISTERS::regWriteWithOpLowByte: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef unsigned char regWriteWithOpHighByte(self, unsigned short regId, unsigned char value, unsigned char valueOp):
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
            value = <unsigned char>(-value)
            return self.regWriteHighByte(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = <unsigned char>(~value)
            return self.regWriteHighByte(regId, value)
        else:
            self.main.notice("REGISTERS::regWriteWithOpHighByte: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef unsigned short regWriteWithOpWord(self, unsigned short regId, unsigned short value, unsigned char valueOp):
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
            value = <unsigned short>(-value)
            return self.regWriteWord(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = <unsigned short>(~value)
            return self.regWriteWord(regId, value)
        else:
            self.main.notice("REGISTERS::regWriteWithOpWord: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef unsigned int regWriteWithOpDword(self, unsigned short regId, unsigned int value, unsigned char valueOp):
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
            value = <unsigned int>(-value)
            return self.regWriteDword(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = <unsigned int>(~value)
            return self.regWriteDword(regId, value)
        else:
            self.main.notice("REGISTERS::regWriteWithOpDword: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef unsigned long int regWriteWithOpQword(self, unsigned short regId, unsigned long int value, unsigned char valueOp):
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
            value = <unsigned long int>(-value)
            return self.regWriteQword(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = <unsigned long int>(~value)
            return self.regWriteQword(regId, value)
        else:
            self.main.notice("REGISTERS::regWriteWithOpQword: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef void setSZP(self, unsigned int value, unsigned char regSize):
        self.sf = (value&BITMASKS_80[regSize])!=0
        self.zf = value==0
        self.pf = PARITY_TABLE[<unsigned char>value]
    cdef void setSZP_O(self, unsigned int value, unsigned char regSize):
        self.setSZP(value, regSize)
        self.of = False
    cdef void setSZP_A(self, unsigned int value, unsigned char regSize):
        self.setSZP(value, regSize)
        self.af = False
    cdef void setSZP_COA(self, unsigned int value, unsigned char regSize):
        self.setSZP(value, regSize)
        self.cf = self.of = self.af = False
    cdef unsigned short getRegNameWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize):
        cdef unsigned short regName
        regName = CPU_REGISTER_NONE
        if (modRMflags & MODRM_FLAGS_SREG):
            regName = CPU_REGISTER_SREG[reg]
        elif (modRMflags & MODRM_FLAGS_CREG):
            regName = CPU_REGISTER_CREG[reg]
        elif (modRMflags & MODRM_FLAGS_DREG):
            if (reg in (4, 5)):
                if (self.getFlagDword( CPU_REGISTER_CR4, CR4_FLAG_DE )):
                    raise HirnwichseException(CPU_EXCEPTION_UD)
                reg += 2
            regName = CPU_REGISTER_DREG[reg]
        else:
            regName = reg
            if (operSize == OP_SIZE_BYTE):
                regName &= 3
        if (regName == CPU_REGISTER_NONE):
            raise HirnwichseException(CPU_EXCEPTION_UD)
        return regName
    cdef unsigned char getCond(self, unsigned char index):
        if (index == 0x0): # O
            return self.of
        elif (index == 0x1): # NO
            return not self.of
        elif (index == 0x2): # B
            return self.cf
        elif (index == 0x3): # NB
            return not self.cf
        elif (index == 0x4): # Z
            return self.zf
        elif (index == 0x5): # NZ
            return not self.zf
        elif (index == 0x6): # BE
            return self.cf or self.zf
        elif (index == 0x7): # NBE
            return not self.cf and not self.zf
        elif (index == 0x8): # S
            return self.sf
        elif (index == 0x9): # NS
            return not self.sf
        elif (index == 0xa): # P
            return self.pf
        elif (index == 0xb): # NP
            return not self.pf
        elif (index == 0xc): # L
            return self.sf != self.of
        elif (index == 0xd): # NL
            return self.sf == self.of
        elif (index == 0xe): # LE
            return self.zf or self.sf != self.of
        elif (index == 0xf): # NLE
            return not self.zf and self.sf == self.of
        else:
            self.main.exitError("getCond: index {0:#04x} is invalid.", index)
    cdef void setFullFlags(self, unsigned long int reg0, unsigned long int reg1, unsigned char regSize, unsigned char method):
        cdef unsigned char unsignedOverflow, signedOverflow, reg0Nibble, regSumuNibble, carried
        cdef unsigned int bitMaskHalf
        cdef unsigned long int regSumu
        carried = False
        bitMaskHalf = BITMASKS_80[regSize]
        if (method in (OPCODE_ADD, OPCODE_ADC)):
            if (method == OPCODE_ADC and self.cf):
                carried = True
                reg1 += 1
            regSumu = <unsigned int>(reg0+reg1)
            if (regSize == OP_SIZE_BYTE):
                regSumu = <unsigned char>regSumu
            elif (regSize == OP_SIZE_WORD):
                regSumu = <unsigned short>regSumu
            unsignedOverflow = (regSumu < reg0 or regSumu < reg1)
            self.pf = PARITY_TABLE[<unsigned char>regSumu]
            self.zf = regSumu==0
            reg0Nibble = reg0&0xf
            regSumuNibble = regSumu&0xf
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSumu &= bitMaskHalf
            signedOverflow = ( ((not reg0 and not reg1) and regSumu) or ((reg0 and reg1) and not regSumu) ) != 0
            self.af = (regSumuNibble<(reg0Nibble+carried))
            self.cf = unsignedOverflow
            self.of = signedOverflow
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
            unsignedOverflow = ((not carried and regSumu > reg0) or (carried and regSumu >= reg0))
            self.pf = PARITY_TABLE[<unsigned char>regSumu]
            self.zf = regSumu==0
            reg0Nibble = reg0&0xf
            regSumuNibble = regSumu&0xf
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSumu &= bitMaskHalf
            signedOverflow = ( ((reg0 and not reg1) and not regSumu) or ((not reg0 and reg1) and regSumu) ) != 0
            self.af = ((regSumuNibble+carried)>reg0Nibble)
            self.cf = unsignedOverflow
            self.of = signedOverflow
            self.sf = regSumu!=0
        elif (method in (OPCODE_MUL, OPCODE_IMUL)):
            regSumu = <unsigned int>(reg0*reg1)
            if (regSize == OP_SIZE_BYTE):
                reg0 = <unsigned char>reg0
                reg1 = <unsigned char>reg1
                regSumu = <unsigned char>regSumu
            elif (regSize == OP_SIZE_WORD):
                reg0 = <unsigned short>reg0
                reg1 = <unsigned short>reg1
                regSumu = <unsigned short>regSumu
            elif (regSize == OP_SIZE_DWORD):
                reg0 = <unsigned int>reg0
                reg1 = <unsigned int>reg1
            self.af = False
            self.cf = self.of = ((reg0 and reg1) and (regSumu < reg0 or regSumu < reg1))
            self.pf = PARITY_TABLE[<unsigned char>regSumu]
            self.zf = regSumu==0
            self.sf = (regSumu & bitMaskHalf) != 0
    """
    cpdef checkMemAccessRights(self, unsigned int mmAddr, unsigned int dataSize, unsigned short segId, unsigned char write):
        cdef GdtEntry gdtEntry
        cdef unsigned char addrInLimit
        cdef unsigned short segVal
        if (not (<Segments>self.segments).isInProtectedMode()):
            return True
        segVal = self.segRead(segId)
        if ( (segVal&0xfff8) == 0 ):
            if (segId == CPU_SEGMENT_SS):
                raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
            else:
                raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
        gdtEntry = (<GdtEntry>(<Gdt>self.segments.gdt).getEntry(segVal))
        if (not gdtEntry or not gdtEntry.segPresent ):
            if (segId == CPU_SEGMENT_SS):
                raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
            else:
                raise HirnwichseException(CPU_EXCEPTION_NP, segVal)
        addrInLimit = gdtEntry.isAddressInLimit(mmAddr, dataSize)
        if (write):
            if ((gdtEntry.segIsCodeSeg or not gdtEntry.segIsRW) or not addrInLimit or ((<Segments>self.segments).isPagingOn() and not (<Paging>(<Segments>self.segments).paging).writeAccessAllowed(mmAddr))):
                if (segId == CPU_SEGMENT_SS):
                    raise HirnwichseException(CPU_EXCEPTION_SS, segVal)
                else:
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
            return True
        else:
            if ((gdtEntry.segIsCodeSeg and not gdtEntry.segIsRW) or not addrInLimit):
                raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
    """
    cdef unsigned int mmGetRealAddr(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride):
        cdef Segment segment
        if (allowOverride and self.segmentOverridePrefix):
            segId = self.segmentOverridePrefix
        segment = self.segments.getSegmentInstance(segId, True)
        mmAddr = <unsigned int>(segment.base+mmAddr)
        # TODO: check for limit asf...
        if (self.vm):
            self.main.exitError("Registers::mmGetRealAddr: TODO. (VM is on)")
        #self.main.notice("test_1: addr: {0:#010x}", mmAddr)
        if ((<Segments>self.segments).isPagingOn()): # TODO: is a20 even applied after paging? (on the physical address... or even the virtual one?)
            return (<Paging>(<Segments>self.segments).paging).getPhysicalAddress(mmAddr)
        if (self.segments.getA20State()): # A20 Active? if True == on, else off
            if (segment.segSize != OP_SIZE_WORD or segment.base >= SIZE_1MB):
                return mmAddr
            return mmAddr&0x1fffff
        elif (segment.segSize == OP_SIZE_WORD and segment.base < SIZE_1MB):
            return mmAddr&0xfffff
        return mmAddr
    cdef bytes mmRead(self, unsigned int mmAddr, unsigned int dataSize, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyRead(mmAddr, dataSize)
    cdef signed char mmReadValueSignedByte(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueSignedByte(mmAddr)
    cdef signed short mmReadValueSignedWord(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueSignedWord(mmAddr)
    cdef signed int mmReadValueSignedDword(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueSignedDword(mmAddr)
    cdef signed long int mmReadValueSignedQword(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueSignedQword(mmAddr)
    cdef signed long int mmReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueSigned(mmAddr, dataSize)
    cdef unsigned char mmReadValueUnsignedByte(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueUnsignedByte(mmAddr)
    cdef unsigned short mmReadValueUnsignedWord(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueUnsignedWord(mmAddr)
    cdef unsigned int mmReadValueUnsignedDword(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueUnsignedDword(mmAddr)
    cdef unsigned long int mmReadValueUnsignedQword(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueUnsignedQword(mmAddr)
    cdef unsigned long int mmReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueUnsigned(mmAddr, dataSize)
    cdef unsigned char mmWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, True)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyWrite(mmAddr, data, dataSize)
    cdef unsigned char mmWriteValueSize(self, unsigned int mmAddr, unsigned_value_types data, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, True)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyWriteValueSize(mmAddr, data)
    cdef unsigned char mmWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, True)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyWriteValue(mmAddr, data, dataSize)
    cdef unsigned_value_types mmWriteValueWithOpSize(self, unsigned int mmAddr, unsigned_value_types data, unsigned short segId, unsigned char allowOverride, unsigned char valueOp):
        cdef unsigned char carryOn
        cdef unsigned_value_types oldData
        if (valueOp == OPCODE_SAVE):
            self.mmWriteValueSize(mmAddr, data, segId, allowOverride)
        else:
            if (valueOp == OPCODE_NEG):
                data = (-data)
                self.mmWriteValueSize(mmAddr, data, segId, allowOverride)
            elif (valueOp == OPCODE_NOT):
                data = (~data)
                self.mmWriteValueSize(mmAddr, data, segId, allowOverride)
            else:
                if (unsigned_value_types is unsigned_char):
                    oldData = self.mmReadValueUnsignedByte(mmAddr, segId, allowOverride)
                elif (unsigned_value_types is unsigned_short):
                    oldData = self.mmReadValueUnsignedWord(mmAddr, segId, allowOverride)
                elif (unsigned_value_types is unsigned_int):
                    oldData = self.mmReadValueUnsignedDword(mmAddr, segId, allowOverride)
                elif (unsigned_value_types is unsigned_long_int):
                    oldData = self.mmReadValueUnsignedQword(mmAddr, segId, allowOverride)
                else:
                    self.main.error("mmWriteValueWithOpSize: invalid unsigned_value_types.")
                    return False
                if (valueOp == OPCODE_ADD):
                    data = (oldData+data)
                    self.mmWriteValueSize(mmAddr, data, segId, allowOverride)
                elif (valueOp in (OPCODE_ADC, OPCODE_SBB)):
                    carryOn = self.cf
                    if (valueOp == OPCODE_ADC):
                        data = (oldData+(data+carryOn))
                    else:
                        data = (oldData-(data+carryOn))
                    self.mmWriteValueSize(mmAddr, data, segId, allowOverride)
                elif (valueOp == OPCODE_SUB):
                    data = (oldData-data)
                    self.mmWriteValueSize(mmAddr, data, segId, allowOverride)
                elif (valueOp == OPCODE_AND):
                    data = (oldData&data)
                    self.mmWriteValueSize(mmAddr, data, segId, allowOverride)
                elif (valueOp == OPCODE_OR):
                    data = (oldData|data)
                    self.mmWriteValueSize(mmAddr, data, segId, allowOverride)
                elif (valueOp == OPCODE_XOR):
                    data = (oldData^data)
                    self.mmWriteValueSize(mmAddr, data, segId, allowOverride)
                else:
                    self.main.exitError("Registers::mmWriteValueWithOpSize: unknown valueOp {0:d}.", valueOp)
        return data
    cdef void run(self):
        self.segments = Segments(self.main)
        self.segments.run()


