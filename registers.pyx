
from misc import ChemuException

include "globals.pxi"
include "cpu_globals.pxi"


# Parity Flag Table: DO NOT EDIT!!!
cdef tuple PARITY_TABLE = (True, False, False, True, False, True, True, False, False, True,
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
    cpdef object modRMOperands(self, unsigned char regSize, unsigned char modRMflags): # regSize in bytes
        cdef unsigned char modRMByte, index
        modRMByte = self.registers.getCurrentOpcodeAddUnsigned(OP_SIZE_BYTE)
        self.rmNameSegId = CPU_SEGMENT_DS
        self.rmName1 = CPU_REGISTER_NONE
        self.rmName2 = 0
        self.rm  = modRMByte&0x7
        self.reg = (modRMByte>>3)&0x7
        self.mod = (modRMByte>>6)&0x3
        self.ss = 0
        self.regName = self.registers.getRegNameWithFlags(modRMflags, self.reg, regSize) # reg
        if (self.mod == 3): # if mod==3, then: reg is source ; rm is dest
            if (regSize == OP_SIZE_BYTE):
                self.rmName0  = CPU_REGISTER_BYTE[self.rm] # rm
            elif (regSize == OP_SIZE_WORD):
                self.rmName0  = CPU_REGISTER_WORD[self.rm] # rm
            elif (regSize == OP_SIZE_DWORD):
                self.rmName0  = CPU_REGISTER_DWORD[self.rm] # rm
            else:
                self.main.exitError("modRMOperands: mod==3; regSize {0:d} not in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)", regSize)
        else:
            if (self.registers.addrSize == OP_SIZE_WORD):
                self.rmName0 = CPU_MODRM_16BIT_RM0[self.rm]
                self.rmName1 = CPU_MODRM_16BIT_RM1[self.rm]
                if (self.mod == 0 and self.rm == 6):
                        self.rmName0 = CPU_REGISTER_NONE
                        self.rmName2 = self.registers.getCurrentOpcodeAddUnsigned(OP_SIZE_WORD)
                elif (self.mod == 1):
                    self.rmName2 = self.registers.getCurrentOpcodeAddSigned(OP_SIZE_BYTE)
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsigned(OP_SIZE_WORD)
                if (self.rmName0 == CPU_REGISTER_BP): # TODO: damn, that can't be correct!?!
                    self.rmNameSegId = CPU_SEGMENT_SS
            elif (self.registers.addrSize == OP_SIZE_DWORD):
                if (self.rm == 4): # If RM==4; then SIB
                    modRMByte = self.registers.getCurrentOpcodeAddUnsigned(OP_SIZE_BYTE)
                    self.rm  = modRMByte&0x7
                    index   = (modRMByte>>3)&7
                    self.ss = (modRMByte>>6)&3
                    if (index != 4):
                        self.rmName1 = CPU_REGISTER_DWORD[index]
                if (self.mod == 0 and self.rm == 5):
                    self.rmName0 = CPU_REGISTER_NONE
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsigned(OP_SIZE_DWORD)
                else:
                    self.rmName0 = CPU_REGISTER_DWORD[self.rm]
                if (self.mod == 1):
                    self.rmName2 = self.registers.getCurrentOpcodeAddSigned(OP_SIZE_BYTE)
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAddUnsigned(OP_SIZE_DWORD)
                if (self.rmName0 in (CPU_REGISTER_ESP, CPU_REGISTER_EBP)):
                    self.rmNameSegId = CPU_SEGMENT_SS
            self.rmNameSegId = self.registers.segmentOverridePrefix or self.rmNameSegId
    cdef unsigned int getRMValueFull(self, unsigned char rmSize):
        cdef unsigned int retAddr
        retAddr = <unsigned int>(self.registers.regReadUnsigned(self.rmName0))
        retAddr = <unsigned int>(retAddr+(self.registers.regReadUnsigned(self.rmName1)<<self.ss))
        retAddr = <unsigned int>(retAddr+self.rmName2)
        if (rmSize == OP_SIZE_WORD):
            return <unsigned short>retAddr
        return retAddr
    cpdef object modRMLoadSigned(self, unsigned char regSize, unsigned char allowOverride):
        # NOTE: imm == unsigned ; disp == signed
        cdef unsigned int mmAddr
        cdef signed long int returnInt
        if (self.mod == 3):
            returnInt = self.registers.regReadSigned(self.rmName0)
        else:
            mmAddr = self.getRMValueFull(self.registers.addrSize)
            returnInt = self.registers.mmReadValueSigned(mmAddr, regSize, self.rmNameSegId, allowOverride)
        if (regSize == OP_SIZE_BYTE):
            returnInt = <signed char>returnInt
        elif (regSize == OP_SIZE_WORD):
            returnInt = <signed short>returnInt
        elif (regSize == OP_SIZE_DWORD):
            returnInt = <signed int>returnInt
        return returnInt
    cpdef object modRMLoadUnsigned(self, unsigned char regSize, unsigned char allowOverride):
        # NOTE: imm == unsigned ; disp == signed
        cdef unsigned int mmAddr
        cdef unsigned long int returnInt
        if (self.mod == 3):
            returnInt = self.registers.regReadUnsigned(self.rmName0)
        else:
            mmAddr = self.getRMValueFull(self.registers.addrSize)
            returnInt = self.registers.mmReadValueUnsigned(mmAddr, regSize, self.rmNameSegId, allowOverride)
        if (regSize == OP_SIZE_BYTE):
            returnInt = <unsigned char>returnInt
        elif (regSize == OP_SIZE_WORD):
            returnInt = <unsigned short>returnInt
        elif (regSize == OP_SIZE_DWORD):
            returnInt = <unsigned int>returnInt
        return returnInt
    cpdef object modRMSave(self, unsigned char regSize, unsigned long int value, unsigned char allowOverride, unsigned char valueOp):
        # stdAllowOverride==True, stdValueOp==OPCODE_SAVE
        cdef unsigned int mmAddr
        if (regSize == OP_SIZE_BYTE):
            value = <unsigned char>value
        elif (regSize == OP_SIZE_WORD):
            value = <unsigned short>value
        elif (regSize == OP_SIZE_DWORD):
            value = <unsigned int>value
        if (self.mod == 3):
            return self.registers.regWriteWithOp(self.rmName0, value, valueOp)
        mmAddr = self.getRMValueFull(self.registers.addrSize)
        return self.registers.mmWriteValueWithOp(mmAddr, value, regSize, self.rmNameSegId, allowOverride, valueOp)
    cdef signed long int modRLoadSigned(self, unsigned char regSize):
        cdef signed long int retVal
        retVal = self.registers.regReadSigned(self.regName)
        if (regSize == OP_SIZE_BYTE):
            retVal = <signed char>retVal
        elif (regSize == OP_SIZE_WORD):
            retVal = <signed short>retVal
        elif (regSize == OP_SIZE_DWORD):
            retVal = <signed int>retVal
        return retVal
    cdef unsigned long int modRLoadUnsigned(self, unsigned char regSize):
        cdef unsigned long int retVal
        retVal = self.registers.regReadUnsigned(self.regName)
        if (regSize == OP_SIZE_BYTE):
            retVal = <unsigned char>retVal
        elif (regSize == OP_SIZE_WORD):
            retVal = <unsigned short>retVal
        elif (regSize == OP_SIZE_DWORD):
            retVal = <unsigned int>retVal
        return retVal
    cdef unsigned long int modRSave(self, unsigned char regSize, unsigned long int value, unsigned char valueOp):
        if (regSize == OP_SIZE_BYTE):
            value = <unsigned char>value
        elif (regSize == OP_SIZE_WORD):
            value = <unsigned short>value
        elif (regSize == OP_SIZE_DWORD):
            value = <unsigned int>value
        return self.registers.regWriteWithOp(self.regName, value, valueOp)



cdef class Registers:
    def __init__(self, object main):
        self.main = main
    cdef void reset(self):
        self.regs.csResetData()
        self.operSize = self.addrSize = 0
        self.resetPrefixes()
        self.segments.reset()
        self.regWrite(CPU_REGISTER_EFLAGS, 0x2)
        self.regWrite(CPU_REGISTER_CR0, 0x40000014)
        self.segWrite(CPU_SEGMENT_CS, 0xf000)
        self.regWrite(CPU_REGISTER_EIP, 0xfff0)
    cdef void resetPrefixes(self):
        self.operandSizePrefix = self.addressSizePrefix = False
        self.segmentOverridePrefix = self.repPrefix = 0
    cdef void readCodeSegSize(self):
        self.getOpAddrCodeSegSize(&self.operSize, &self.addrSize)
    cdef unsigned char getCPL(self):
        if (not (<Segments>self.segments).isInProtectedMode()):
            return 0
        return (<Segment>(self.segments.cs).segmentIndex&3)
    cdef unsigned char getIOPL(self):
        return (self.getEFLAG(FLAG_IOPL)>>12)&3
    cpdef signed long int getCurrentOpcodeSigned(self, unsigned char numBytes):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsigned(self.eipSizeRegId)
        return self.mmReadValueSigned(opcodeAddr, numBytes, CPU_SEGMENT_CS, False)
    cpdef unsigned long int getCurrentOpcodeUnsigned(self, unsigned char numBytes):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsigned(self.eipSizeRegId)
        return self.mmReadValueUnsigned(opcodeAddr, numBytes, CPU_SEGMENT_CS, False)
    cpdef signed long int getCurrentOpcodeAddSigned(self, unsigned char numBytes):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsigned(self.eipSizeRegId)
        self.regWrite(self.eipSizeRegId, <unsigned int>(opcodeAddr+numBytes))
        return self.mmReadValueSigned(opcodeAddr, numBytes, CPU_SEGMENT_CS, False)
    cpdef unsigned long int getCurrentOpcodeAddUnsigned(self, unsigned char numBytes):
        cdef unsigned int opcodeAddr
        opcodeAddr = self.regReadUnsigned(self.eipSizeRegId)
        self.regWrite(self.eipSizeRegId, <unsigned int>(opcodeAddr+numBytes))
        return self.mmReadValueUnsigned(opcodeAddr, numBytes, CPU_SEGMENT_CS, False)
    cdef unsigned char getCurrentOpcodeAddWithAddr(self, unsigned short *retSeg, unsigned int *retAddr):
        retSeg[0]  = self.segRead(CPU_SEGMENT_CS)
        retAddr[0] = self.regReadUnsigned(self.eipSizeRegId)
        self.regWrite(self.eipSizeRegId, <unsigned int>(retAddr[0]+OP_SIZE_BYTE))
        return self.mmReadValueUnsigned(retAddr[0], OP_SIZE_BYTE, CPU_SEGMENT_CS, False)
    cdef unsigned char getRegSize(self, unsigned short regId):
        if (regId in CPU_REGISTER_BYTE):
            return OP_SIZE_BYTE
        elif (regId in CPU_REGISTER_WORD):
            return OP_SIZE_WORD
        elif (regId in CPU_REGISTER_DWORD):
            return OP_SIZE_DWORD
        elif (regId in CPU_REGISTER_QWORD):
            return OP_SIZE_QWORD
        self.main.exitError("regId is unknown! ({0:d})", regId)
    cdef unsigned short segRead(self, unsigned short segId):
        IF STRICT_CHECKS:
            if (not segId or not (segId in CPU_REGISTER_SREG)):
                self.main.exitError("segRead: segId is not a segment! ({0:d})", segId)
                return 0
        segId = CPU_REG_DATA_OFFSETS[segId]
        # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        segId = self.regs.csReadValueUnsignedBE(segId, OP_SIZE_WORD)
        return segId
    cdef unsigned short segWrite(self, unsigned short segId, unsigned short segValue):
        cdef Segment segmentInstance
        IF STRICT_CHECKS:
            if (not segId or not (segId in CPU_REGISTER_SREG)):
                self.main.exitError("segWrite: segId is not a segment! ({0:d})", segId)
                return 0
        if ((<Segments>self.segments).isInProtectedMode()):
            (<Segments>self.segments).checkSegmentLoadAllowed(segValue, segId == CPU_SEGMENT_SS)
        segmentInstance = <Segment>(self.segments.getSegmentInstance(segId, False))
        segmentInstance.loadSegment(segValue)
        if (segId == CPU_SEGMENT_CS):
            self.codeSegSize = segmentInstance.getSegSize()
            self.eipSizeRegId = CPU_REGISTER_EIP if (self.codeSegSize == OP_SIZE_DWORD) else CPU_REGISTER_IP
        segId = CPU_REG_DATA_OFFSETS[segId]
        # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        self.regs.csWriteValueBE(segId, segValue, OP_SIZE_WORD)
        return segValue
    cdef signed long int regReadSigned(self, unsigned short regId):
        cdef unsigned char opSize
        if (regId == CPU_REGISTER_NONE):
            return 0
        IF STRICT_CHECKS:
            if (regId < CPU_MIN_REGISTER or regId >= CPU_MAX_REGISTER):
                self.main.exitError("regRead: regId is reserved! ({0:d})", regId)
                return 0
        opSize = self.getRegSize(regId)
        regId = CPU_REG_DATA_OFFSETS[regId]
        # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        return self.regs.csReadValueSignedBE(regId, opSize)
    cdef unsigned long int regReadUnsigned(self, unsigned short regId):
        cdef unsigned char opSize
        if (regId == CPU_REGISTER_NONE):
            return 0
        IF STRICT_CHECKS:
            if (regId < CPU_MIN_REGISTER or regId >= CPU_MAX_REGISTER):
                self.main.exitError("regRead: regId is reserved! ({0:d})", regId)
                return 0
        opSize = self.getRegSize(regId)
        regId = CPU_REG_DATA_OFFSETS[regId]
        # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        return self.regs.csReadValueUnsignedBE(regId, opSize)
    cdef unsigned int regWrite(self, unsigned short regId, unsigned int value):
        cdef unsigned char opSize
        if (regId == CPU_REGISTER_NONE):
            self.main.exitError("regWrite: regId is CPU_REGISTER_NONE!")
            return 0
        IF STRICT_CHECKS:
            if (regId < CPU_MIN_REGISTER or regId >= CPU_MAX_REGISTER):
                self.main.exitError("regWrite: regId is reserved! ({0:d})", regId)
                return 0
        opSize = self.getRegSize(regId)
        regId = CPU_REG_DATA_OFFSETS[regId]
        # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        value = self.regs.csWriteValueBE(regId, value, opSize)
        return value # returned value is unsigned!!
    cdef unsigned int regAdd(self, unsigned short regId, unsigned int value):
        return self.regWrite(regId, <unsigned int>(self.regReadUnsigned(regId)+value))
    cdef unsigned int regAdc(self, unsigned short regId, unsigned int value):
        return self.regAdd  (regId, <unsigned int>(value+self.getEFLAG( FLAG_CF )))
    cdef unsigned int regSub(self, unsigned short regId, unsigned int value):
        return self.regWrite(regId, <unsigned int>(self.regReadUnsigned(regId)-value))
    cdef unsigned int regSbb(self, unsigned short regId, unsigned int value):
        return self.regSub  (regId, <unsigned int>(value+self.getEFLAG( FLAG_CF )))
    cdef unsigned int regXor(self, unsigned short regId, unsigned int value):
        return self.regWrite(regId, <unsigned int>(self.regReadUnsigned(regId)^value))
    cdef unsigned int regAnd(self, unsigned short regId, unsigned int value):
        return self.regWrite(regId, <unsigned int>(self.regReadUnsigned(regId)&value))
    cdef unsigned int regOr (self, unsigned short regId, unsigned int value):
        return self.regWrite(regId, <unsigned int>(self.regReadUnsigned(regId)|value))
    cdef unsigned int regNeg(self, unsigned short regId):
        return self.regWrite(regId, <unsigned int>(-self.regReadUnsigned(regId)))
    cdef unsigned int regNot(self, unsigned short regId):
        return self.regWrite(regId, <unsigned int>(~self.regReadUnsigned(regId)))
    cdef unsigned int regWriteWithOp(self, unsigned short regId, unsigned int value, unsigned char valueOp):
        if (valueOp == OPCODE_SAVE):
            return self.regWrite(regId, value)
        elif (valueOp == OPCODE_ADD):
            return self.regAdd(regId, value)
        elif (valueOp == OPCODE_ADC):
            return self.regAdc(regId, value)
        elif (valueOp == OPCODE_SUB):
            return self.regSub(regId, value)
        elif (valueOp == OPCODE_SBB):
            return self.regSbb(regId, value)
        elif (valueOp == OPCODE_AND):
            return self.regAnd(regId, value)
        elif (valueOp == OPCODE_OR):
            return self.regOr(regId, value)
        elif (valueOp == OPCODE_XOR):
            return self.regXor(regId, value)
        elif (valueOp == OPCODE_NEG):
            value = <unsigned int>(-value)
            return self.regWrite(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = <unsigned int>(~value)
            return self.regWrite(regId, value)
        else:
            self.main.notice("REGISTERS::regWriteWithOp: unknown valueOp {0:d}.", valueOp)
    cdef unsigned int valSetBit(self, unsigned int value, unsigned char bit, unsigned char state):
        if (state):
            return ( value | <unsigned int>(1<<bit) )
        return ( value & <unsigned int>(~(1<<bit)) )
    cdef unsigned char valGetBit(self, unsigned int value, unsigned char bit): # return True if bit is set, otherwise False
        return (value&<unsigned int>(1<<bit))!=0
    cdef unsigned int getEFLAG(self, unsigned int flags):
        return self.getFlag(CPU_REGISTER_EFLAGS, flags)
    cdef unsigned int setEFLAG(self, unsigned int flags, unsigned char flagState):
        if (flagState):
            return self.regOr(CPU_REGISTER_EFLAGS, flags)
        return self.regAnd(CPU_REGISTER_EFLAGS, <unsigned int>(~flags))
    cdef unsigned int getFlag(self, unsigned short regId, unsigned int flags):
        return (self.regReadUnsigned(regId)&flags)
    cdef unsigned short getWordAsDword(self, unsigned short regWord, unsigned char wantRegSize):
        if (regWord in CPU_REGISTER_BYTE):
            # regWord should be lbyte...
            if (regWord in CPU_REGISTER_HBYTE):
                regWord += 1
            if (wantRegSize == OP_SIZE_BYTE):
                return regWord
            elif (wantRegSize == OP_SIZE_WORD):
                return regWord-2
            elif (wantRegSize == OP_SIZE_DWORD):
                return regWord-3
            elif (wantRegSize == OP_SIZE_QWORD):
                return regWord-4
        elif (regWord in CPU_REGISTER_WORD):
            if (wantRegSize == OP_SIZE_BYTE):
                return regWord+2 # return lbyte
            elif (wantRegSize == OP_SIZE_WORD):
                return regWord
            elif (wantRegSize == OP_SIZE_DWORD):
                return regWord-1
            elif (wantRegSize == OP_SIZE_QWORD):
                return regWord-2
        elif (regWord in CPU_REGISTER_DWORD):
            if (wantRegSize == OP_SIZE_BYTE):
                return regWord+3 # return lbyte
            elif (wantRegSize == OP_SIZE_WORD):
                return regWord+1
            elif (wantRegSize == OP_SIZE_DWORD):
                return regWord
            elif (wantRegSize == OP_SIZE_QWORD):
                return regWord-1
        elif (regWord in CPU_REGISTER_QWORD):
            if (wantRegSize == OP_SIZE_BYTE):
                return regWord+4 # return lbyte
            elif (wantRegSize == OP_SIZE_WORD):
                return regWord+2
            elif (wantRegSize == OP_SIZE_DWORD):
                return regWord+1
            elif (wantRegSize == OP_SIZE_QWORD):
                return regWord
        self.main.exitError("unknown case. (regWord: {0:d}, wantRegSize: {1:d})", regWord, wantRegSize)
        return 0
    cdef void setSZP(self, unsigned int value, unsigned char regSize):
        self.setEFLAG(FLAG_SF, (value&(<Misc>self.main.misc).getBitMask80(regSize))!=0)
        self.setEFLAG(FLAG_ZF, value==0)
        self.setEFLAG(FLAG_PF, PARITY_TABLE[<unsigned char>value])
    cdef void setSZP_O0(self, unsigned int value, unsigned char regSize):
        self.setSZP(value, regSize)
        self.setEFLAG(FLAG_OF, False)
    cdef void setSZP_C0_O0_A0(self, unsigned int value, unsigned char regSize):
        self.setSZP_O0(value, regSize)
        self.setEFLAG(FLAG_CF | FLAG_AF, False)
    cdef unsigned short getRegNameWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize):
        cdef unsigned short regName
        regName = CPU_REGISTER_NONE
        if (modRMflags & MODRM_FLAGS_SREG):
            regName = CPU_REGISTER_SREG[reg]
        elif (modRMflags & MODRM_FLAGS_CREG):
            regName = CPU_REGISTER_CREG[reg]
        elif (modRMflags & MODRM_FLAGS_DREG):
            if (reg in (4, 5)):
                if (self.getFlag( CPU_REGISTER_CR4, CR4_FLAG_DE )):
                    raise ChemuException(CPU_EXCEPTION_UD)
                reg += 2
            regName = CPU_REGISTER_DREG[reg]
        else:
            if (operSize == OP_SIZE_BYTE):
                regName = CPU_REGISTER_BYTE[reg]
            elif (operSize == OP_SIZE_WORD):
                regName = CPU_REGISTER_WORD[reg]
            elif (operSize == OP_SIZE_DWORD):
                regName = CPU_REGISTER_DWORD[reg]
            else:
                self.main.exitError("getRegNameWithFlags: operSize not in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)")
        if (not regName):
            raise ChemuException(CPU_EXCEPTION_UD)
        return regName
    cdef unsigned char getCond(self, unsigned char index):
        if (index == 0x0): # O
            return self.getEFLAG(FLAG_OF)!=0
        elif (index == 0x1): # NO
            return self.getEFLAG(FLAG_OF)==0
        elif (index == 0x2): # B
            return self.getEFLAG(FLAG_CF)
        elif (index == 0x3): # NB
            return self.getEFLAG(FLAG_CF)==0
        elif (index == 0x4): # E
            return self.getEFLAG(FLAG_ZF)!=0
        elif (index == 0x5): # NE
            return self.getEFLAG(FLAG_ZF)==0
        elif (index == 0x6): # BE
            return self.getEFLAG(FLAG_CF_ZF)!=0
        elif (index == 0x7): # NBE
            return self.getEFLAG(FLAG_CF_ZF)==0
        elif (index == 0x8): # S
            return self.getEFLAG(FLAG_SF)!=0
        elif (index == 0x9): # NS
            return self.getEFLAG(FLAG_SF)==0
        elif (index == 0xa): # P
            return self.getEFLAG(FLAG_PF)!=0
        elif (index == 0xb): # NP
            return self.getEFLAG(FLAG_PF)==0
        elif (index == 0xc): # L
            return (self.getEFLAG(FLAG_SF_OF) in (FLAG_SF, FLAG_OF))
        elif (index == 0xd): # NL
            return (self.getEFLAG(FLAG_SF_OF) in (0, FLAG_SF_OF))
        elif (index == 0xe): # LE
            return (self.getEFLAG(FLAG_ZF)!=0 or ((self.getEFLAG(FLAG_SF_OF) in (FLAG_SF, FLAG_OF))) )
        elif (index == 0xf): # NLE
            return (self.getEFLAG(FLAG_SF_OF_ZF) in (0, FLAG_SF_OF))
        else:
            self.main.exitError("getCond: index {0:#x} invalid.", index)
    cdef void setFullFlags(self, unsigned long int reg0, unsigned long int reg1, unsigned char regSize, unsigned char method):
        cdef unsigned char unsignedOverflow, signedOverflow, isResZero, afFlag, reg0Nibble, reg1Nibble, regSumNibble, carried
        cdef unsigned int bitMaskHalf
        cdef unsigned long int regSumu
        cdef signed long int regSum
        afFlag = carried = False
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(regSize)

        if (method in (OPCODE_ADD, OPCODE_ADC)):
            if (method == OPCODE_ADC and self.getEFLAG(FLAG_CF)):
                carried = True
                reg1 += 1
            regSumu = <unsigned int>(reg0+reg1)
            if (regSize == OP_SIZE_BYTE):
                regSumu = <unsigned char>regSumu
            elif (regSize == OP_SIZE_WORD):
                regSumu = <unsigned short>regSumu
            isResZero = regSumu==0
            unsignedOverflow = (regSumu < reg0 or regSumu < reg1)
            self.setEFLAG(FLAG_PF, PARITY_TABLE[<unsigned char>regSumu])
            self.setEFLAG(FLAG_ZF, isResZero)
            reg0Nibble = reg0&0xf
            reg1Nibble = reg1&0xf
            regSumNibble = regSumu&0xf
            if ((carried and regSumNibble<=reg0Nibble) or regSumNibble<reg0Nibble):
                afFlag = True
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSumu &= bitMaskHalf
            signedOverflow = ( ((not reg0 and not reg1) and regSumu) or ((reg0 and reg1) and not regSumu) ) != 0
            self.setEFLAG(FLAG_AF, afFlag)
            self.setEFLAG(FLAG_CF, unsignedOverflow)
            self.setEFLAG(FLAG_OF, (not isResZero and signedOverflow))
            self.setEFLAG(FLAG_SF, regSumu!=0)
        elif (method in (OPCODE_SUB, OPCODE_SBB)):
            if (method == OPCODE_SBB and self.getEFLAG(FLAG_CF)):
                carried = True
                reg1 += 1
            regSumu = <unsigned int>(reg0-reg1)
            if (regSize == OP_SIZE_BYTE):
                regSumu = <unsigned char>regSumu
            elif (regSize == OP_SIZE_WORD):
                regSumu = <unsigned short>regSumu
            isResZero = regSumu==0
            unsignedOverflow = ((not carried and regSumu > reg0) or (carried and regSumu >= reg0))
            self.setEFLAG(FLAG_PF, PARITY_TABLE[<unsigned char>regSumu])
            self.setEFLAG(FLAG_ZF, isResZero)
            reg0Nibble = reg0&0xf
            reg1Nibble = reg1&0xf
            regSumNibble = regSumu&0xf
            if ((carried and regSumNibble>=reg0Nibble) or regSumNibble>reg0Nibble):
                afFlag = True
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSumu &= bitMaskHalf
            signedOverflow = ( ((reg0 and not reg1) and not regSumu) or ((not reg0 and reg1) and regSumu) ) != 0
            self.setEFLAG(FLAG_AF, afFlag)
            self.setEFLAG(FLAG_CF, unsignedOverflow )
            self.setEFLAG(FLAG_OF, (not isResZero and signedOverflow))
            self.setEFLAG(FLAG_SF, regSumu!=0)
        elif (method in (OPCODE_MUL, OPCODE_IMUL)):
            if (regSize == OP_SIZE_BYTE):
                regSum = <signed short>((<signed char>reg0)*(<signed char>reg1))
                reg0 = <unsigned char>reg0
                reg1 = <unsigned char>reg1
                regSumu = <unsigned char>(reg0*reg1)
                isResZero = (<unsigned short>regSum)==0
                if (method == OPCODE_MUL):
                    self.setEFLAG(FLAG_CF | FLAG_OF, ((reg0 and reg1) and (regSumu < reg0 or regSumu < reg1)))
            elif (regSize == OP_SIZE_WORD):
                regSum = <signed int>((<signed short>reg0)*(<signed short>reg1))
                reg0 = <unsigned short>reg0
                reg1 = <unsigned short>reg1
                regSumu = <unsigned short>(reg0*reg1)
                isResZero = (<unsigned int>regSum)==0
                if (method == OPCODE_MUL):
                    self.setEFLAG(FLAG_CF | FLAG_OF, ((reg0 and reg1) and (regSumu < reg0 or regSumu < reg1)))
            elif (regSize == OP_SIZE_DWORD):
                regSum = <signed long int>((<signed int>reg0)*(<signed int>reg1))
                reg0 = <unsigned int>reg0
                reg1 = <unsigned int>reg1
                regSumu = <unsigned int>(reg0*reg1)
                isResZero = (<unsigned long int>regSum)==0
                if (method == OPCODE_MUL):
                    self.setEFLAG(FLAG_CF | FLAG_OF, ((reg0 and reg1) and (regSumu < reg0 or regSumu < reg1)))
            if (method == OPCODE_IMUL):
                self.setEFLAG(FLAG_CF | FLAG_OF, (regSumu>>(regSize<<3))!=0)
            self.setEFLAG(FLAG_PF, PARITY_TABLE[<unsigned char>regSum])
            self.setEFLAG(FLAG_ZF, isResZero)
            if (regSize == OP_SIZE_BYTE):
                regSum = <signed char>regSum
            self.setEFLAG(FLAG_SF, regSum<0)
    cdef void checkMemAccessRights(self, unsigned int mmAddr, unsigned int dataSize, unsigned short segId, unsigned char write):
        cdef GdtEntry gdtEntry
        cdef unsigned char addrInLimit
        cdef unsigned short segVal
        if (not self.segments.isInProtectedMode()):
            return
        segVal = self.segRead(segId)
        if ( (segVal&0xfff8) == 0 ):
            if (segId == CPU_SEGMENT_SS):
                raise ChemuException(CPU_EXCEPTION_SS, segVal)
            else:
                raise ChemuException(CPU_EXCEPTION_GP, segVal)
        gdtEntry = (<GdtEntry>(<Gdt>self.segments.gdt).getEntry(segVal))
        if (not gdtEntry or not gdtEntry.segPresent ):
            if (segId == CPU_SEGMENT_SS):
                raise ChemuException(CPU_EXCEPTION_SS, segVal)
            else:
                raise ChemuException(CPU_EXCEPTION_NP, segVal)
        addrInLimit = gdtEntry.isAddressInLimit(mmAddr, dataSize)
        if (write):
            if ((gdtEntry.segIsCodeSeg or not gdtEntry.segIsRW) or not addrInLimit):
                if (segId == CPU_SEGMENT_SS):
                    raise ChemuException(CPU_EXCEPTION_SS, segVal)
                else:
                    raise ChemuException(CPU_EXCEPTION_GP, segVal)
        else:
            if ((gdtEntry.segIsCodeSeg and not gdtEntry.segIsRW) or not addrInLimit):
                raise ChemuException(CPU_EXCEPTION_GP, segVal)
    cdef unsigned int mmGetRealAddr(self, unsigned int mmAddr, unsigned short segId, unsigned char allowOverride):
        cdef Segment segment
        if (allowOverride and self.segmentOverridePrefix):
            segId = self.segmentOverridePrefix
        segment = self.segments.getSegmentInstance(segId, True)
        mmAddr = <unsigned int>(segment.base+mmAddr)
        # TODO: check for limit asf...
        if (not self.segments.isInProtectedMode()):
            if (self.segments.getA20State()): # A20 Active? if True == on, else off
                if (segment.segSize != OP_SIZE_WORD or segment.base >= SIZE_1MB):
                    return mmAddr&0xff1fffff
                return mmAddr&0x1fffff
            if (segment.segSize == OP_SIZE_WORD and segment.base < SIZE_1MB):
                return mmAddr&0xfffff
        return mmAddr
    cpdef object mmRead(self, unsigned int mmAddr, unsigned int dataSize, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyRead(mmAddr, dataSize)
    cpdef object mmReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride):
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueSigned(mmAddr, dataSize)
    cpdef object mmReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride):
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueUnsigned(mmAddr, dataSize)
    cpdef object mmWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(mmAddr, dataSize, segId, True)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        (<Mm>self.main.mm).mmPhyWrite(mmAddr, data, dataSize)
    cpdef object mmWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize, unsigned short segId, unsigned char allowOverride):
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyWriteValue(mmAddr, data, dataSize)
    cpdef object mmWriteValueWithOp(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize, unsigned short segId, unsigned char allowOverride, unsigned char valueOp):
        cdef unsigned char carryOn
        cdef unsigned long int oldData
        if (valueOp == OPCODE_SAVE):
            return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
        else:
            if (valueOp == OPCODE_NEG):
                data = <unsigned long int>(-data)
                return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
            elif (valueOp == OPCODE_NOT):
                data = <unsigned long int>(~data)
                return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
            else:
                oldData = self.mmReadValueUnsigned(mmAddr, dataSize, segId, allowOverride)
                if (valueOp == OPCODE_ADD):
                    data = <unsigned long int>(oldData+data)
                    return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
                elif (valueOp in (OPCODE_ADC, OPCODE_SBB)):
                    carryOn = self.getEFLAG( FLAG_CF )
                    if (valueOp == OPCODE_ADC):
                        data = <unsigned long int>(oldData+<unsigned long int>(data+carryOn))
                    else:
                        data = <unsigned long int>(oldData-<unsigned long int>(data+carryOn))
                    return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
                elif (valueOp == OPCODE_SUB):
                    data = <unsigned long int>(oldData-data)
                    return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
                elif (valueOp == OPCODE_AND):
                    return self.mmWriteValue(mmAddr, (oldData&data), dataSize, segId, allowOverride)
                elif (valueOp == OPCODE_OR):
                    return self.mmWriteValue(mmAddr,(oldData|data), dataSize, segId, allowOverride)
                elif (valueOp == OPCODE_XOR):
                    return self.mmWriteValue(mmAddr, (oldData^data), dataSize, segId, allowOverride)
        self.main.exitError("Registers::mmWriteValueWithOp: unknown valueOp {0:d}.", valueOp)
        return 0
    cdef unsigned char getSegSize(self, unsigned short segId):
        return (<Segment>(self.segments.getSegmentInstance(segId, True))).getSegSize()
    cdef unsigned char isSegPresent(self, unsigned short segId):
        return (((<Segment>(self.segments.getSegmentInstance(segId, True))).accessByte & GDT_ACCESS_PRESENT) != 0)
    cdef unsigned char getOpSegSize(self, unsigned short segId):
        segId = <unsigned char>self.getSegSize(segId)
        return <unsigned char>((((segId==OP_SIZE_WORD)==self.operandSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
    cdef unsigned char getAddrSegSize(self, unsigned short segId):
        segId = <unsigned char>self.getSegSize(segId)
        return <unsigned char>((((segId==OP_SIZE_WORD)==self.addressSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
    cdef void getOpAddrSegSize(self, unsigned short segId, unsigned char *opSize, unsigned char *addrSize):
        segId = <unsigned char>self.getSegSize(segId)
        opSize[0]   = ((((segId==OP_SIZE_WORD)==self.operandSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
        addrSize[0] = ((((segId==OP_SIZE_WORD)==self.addressSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
    cdef unsigned char getOpCodeSegSize(self):
        return <unsigned char>((((self.codeSegSize==OP_SIZE_WORD)==self.operandSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
    cdef unsigned char getAddrCodeSegSize(self):
        return <unsigned char>((((self.codeSegSize==OP_SIZE_WORD)==self.addressSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
    cdef void getOpAddrCodeSegSize(self, unsigned char *opSize, unsigned char *addrSize):
        opSize[0]   = ((((self.codeSegSize==OP_SIZE_WORD)==self.operandSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
        addrSize[0] = ((((self.codeSegSize==OP_SIZE_WORD)==self.addressSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
    cdef void run(self):
        self.regs = ConfigSpace(CPU_REGISTER_LENGTH, self.main)
        self.segments = Segments(self.main)
        self.regs.run()
        self.segments.run()


