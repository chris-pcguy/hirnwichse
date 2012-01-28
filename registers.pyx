
from misc import ChemuException

include "globals.pxi"


cdef class ModRMClass:
    def __init__(self, object main, Registers registers):
        self.main = main
        self.registers = registers
    cdef resetVars(self, unsigned char modRMByte):
        self.rmNameSegId = CPU_SEGMENT_DS
        self.rmName1 = CPU_REGISTER_NONE
        self.rmName2 = 0
        self.rm  = modRMByte&0x7
        self.reg = (modRMByte>>3)&0x7
        self.mod = (modRMByte>>6)&0x3
    cdef copyRMVars(self, ModRMClass otherInstance):
        self.regName = otherInstance.regName
    cdef sibOperands(self):
        cdef unsigned char sibByte, base, index, ss
        cdef unsigned short indexReg
        sibByte = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        base    = (sibByte)&7
        index   = (sibByte>>3)&7
        if (index == 4):
            self.rmName2 = 0
        else:
            ss = (sibByte>>6)&3
            indexReg = CPU_REGISTER_DWORD[index]
            self.rmName2 = ((self.registers.regRead( indexReg, False ) * (1 << ss))&BITMASK_DWORD)
        if (self.mod == 0 and base == 5):
            self.rmName0 = CPU_REGISTER_NONE
            self.rmName2 += self.registers.getCurrentOpcodeAdd(OP_SIZE_DWORD, False)
        else:
            self.rmName0 = CPU_REGISTER_DWORD[base]
        # Don't add disp8/disp32 to rmName2 here, as it get done in modRMOperands
    cdef modRMOperands(self, unsigned char regSize, unsigned char modRMflags): # regSize in bytes
        self.resetVars(self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False))
        self.regName = self.registers.getRegNameWithFlags(modRMflags, self.reg, regSize) # source
        if (self.mod == 3): # reg: source ; rm: dest
            if (regSize == OP_SIZE_BYTE):
                self.rmName0  = CPU_REGISTER_BYTE[self.rm] # dest
            elif (regSize == OP_SIZE_WORD):
                self.rmName0  = CPU_REGISTER_WORD[self.rm] # dest
            elif (regSize == OP_SIZE_DWORD):
                self.rmName0  = CPU_REGISTER_DWORD[self.rm] # dest
            else:
                self.main.exitError("modRMOperands: mod==3; regSize {0:d} not in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)", regSize)
        else:
            regSize = self.registers.getAddrCodeSegSize()
            if (regSize == OP_SIZE_WORD):
                if (self.rm in (0, 1, 7)):
                    self.rmName0 = CPU_REGISTER_BX
                elif (self.rm in (2, 3)):
                    self.rmName0 = CPU_REGISTER_BP
                elif (self.rm == 4):
                    self.rmName0 = CPU_REGISTER_SI
                elif (self.rm == 5):
                    self.rmName0 = CPU_REGISTER_DI
                elif (self.rm == 6):
                    if (self.mod == 0):
                        self.rmName0 = CPU_REGISTER_NONE
                        self.rmName2 = self.registers.getCurrentOpcodeAdd(OP_SIZE_WORD, False)
                    else:
                        self.rmName0 = CPU_REGISTER_BP
                if (self.rm in (0, 2)):
                    self.rmName1 = CPU_REGISTER_SI
                elif (self.rm in (1, 3)):
                    self.rmName1 = CPU_REGISTER_DI
                if (self.mod == 1):
                    self.rmName2 = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, True)
                elif (self.mod == 2):
                    self.rmName2 = self.registers.getCurrentOpcodeAdd(OP_SIZE_WORD, False)
            elif (regSize == OP_SIZE_DWORD):
                if (self.rm == 4): # SIB
                    self.sibOperands()
                elif (self.rm == 5):
                    if (self.mod == 0):
                        self.rmName0 = CPU_REGISTER_NONE
                        self.rmName2 = self.registers.getCurrentOpcodeAdd(OP_SIZE_DWORD, False)
                    else:
                        self.rmName0 = CPU_REGISTER_EBP
                else:
                    self.rmName0 = CPU_REGISTER_DWORD[self.rm]
                if (self.mod == 1):
                    self.rmName2 += self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, True)
                elif (self.mod == 2):
                    self.rmName2 += self.registers.getCurrentOpcodeAdd(OP_SIZE_DWORD, False)
            else:
                self.main.exitError("modRMOperands: AddrSegSize(CS) not in (OP_SIZE_WORD, OP_SIZE_DWORD)")
                return
            if (self.rmName0 in (CPU_REGISTER_BP, CPU_REGISTER_EBP)): # TODO: only use this if mod in (0,1,2)???
                self.rmNameSegId = CPU_SEGMENT_SS
            self.rmNameSegId = self.registers.segmentOverridePrefix or self.rmNameSegId
    cdef modRMOperandsResetEip(self, unsigned char regSize, unsigned char modRMflags):
        cdef unsigned long oldEip
        oldEip = self.registers.regRead( CPU_REGISTER_EIP, False )
        self.modRMOperands(regSize, modRMflags)
        self.registers.regWrite( CPU_REGISTER_EIP, oldEip )
    cdef unsigned long long getRMValueFull(self, unsigned char rmSize):
        return ((self.registers.regRead(self.rmName0, False)+self.registers.regRead(self.rmName1, False)\
                        +self.rmName2)&((<Misc>self.main.misc).getBitMaskFF(rmSize)))
    cdef long long modRMLoad(self, unsigned char regSize, unsigned char signed, unsigned char allowOverride):
        # NOTE: imm == unsigned ; disp == signed
        cdef unsigned char addrSize
        cdef long long returnInt
        if (self.mod == 3):
            returnInt = self.registers.regRead(self.rmName0, signed)
        else:
            addrSize = self.registers.getAddrCodeSegSize()
            returnInt = self.getRMValueFull(addrSize)
            if (signed):
                returnInt = self.registers.mmReadValueSigned(returnInt, regSize, self.rmNameSegId, allowOverride)
            else:
                returnInt = self.registers.mmReadValueUnsigned(returnInt, regSize, self.rmNameSegId, allowOverride)
        return returnInt
    cdef unsigned long long modRMSave(self, unsigned char regSize, unsigned long long value, unsigned char allowOverride, unsigned char valueOp):
        # stdAllowOverride==True, stdValueOp==OPCODE_SAVE
        cdef unsigned char addrSize
        cdef long long rmValueFull
        if (self.mod == 3):
            return self.registers.regWriteWithOp(self.rmName0, value, valueOp)
        addrSize = self.registers.getAddrCodeSegSize()
        rmValueFull = self.getRMValueFull(addrSize)
        return self.registers.mmWriteValueWithOp(rmValueFull, value, regSize, self.rmNameSegId, allowOverride, valueOp)
    cdef unsigned short modSegLoad(self):
        return self.registers.segRead(self.regName)
    cdef unsigned short modSegSave(self, unsigned char regSize, unsigned long long value):
        if (self.regName == CPU_SEGMENT_CS):
            raise ChemuException(CPU_EXCEPTION_UD)
        return self.registers.segWrite(self.regName, value)
    cdef long long modRLoad(self, unsigned char regSize, unsigned char signed):
        return self.registers.regRead(self.regName, signed)
    cdef unsigned long long modRSave(self, unsigned char regSize, unsigned long long value, unsigned char valueOp):
        return self.registers.regWriteWithOp(self.regName, value, valueOp)



cdef class Registers:
    def __init__(self, object main):
        self.main = main
    cdef reset(self):
        self.regs.csResetData()
        self.cpl = self.iopl = 0
        self.resetPrefixes()
        self.segments.reset()
        self.regWrite(CPU_REGISTER_EFLAGS, 0x2)
        self.segWrite(CPU_SEGMENT_CS, 0xf000)
        self.regWrite(CPU_REGISTER_EIP, 0xfff0)
        self.regWrite(CPU_REGISTER_CR0, 0x60000034)
    cdef resetPrefixes(self):
        self.repPrefix = self.operandSizePrefix = self.addressSizePrefix = False
        self.segmentOverridePrefix = 0
    cdef long long getCurrentOpcode(self, unsigned char numBytes, unsigned char signed):
        cdef unsigned long opcodeAddr
        opcodeAddr = self.regRead(self.eipSizeRegId, False)
        if (signed):
            return self.mmReadValueSigned(opcodeAddr, numBytes, CPU_SEGMENT_CS, False)
        return self.mmReadValueUnsigned(opcodeAddr, numBytes, CPU_SEGMENT_CS, False)
    cdef long long getCurrentOpcodeAdd(self, unsigned char numBytes, unsigned char signed):
        cdef unsigned long opcodeAddr
        opcodeAddr = self.regAdd(self.eipSizeRegId, numBytes)-numBytes
        if (signed):
            return self.mmReadValueSigned(opcodeAddr, numBytes, CPU_SEGMENT_CS, False)
        return self.mmReadValueUnsigned(opcodeAddr, numBytes, CPU_SEGMENT_CS, False)
    cdef unsigned char getCurrentOpcodeAddWithAddr(self, unsigned short *retSeg, unsigned long *retAddr):
        retSeg[0]  = self.segRead(CPU_SEGMENT_CS)
        retAddr[0] = self.regAddReturnOrig(self.eipSizeRegId, 1)
        return self.mmReadValueUnsigned(retAddr[0], OP_SIZE_BYTE, CPU_SEGMENT_CS, False)
    cdef unsigned short getRegSize(self, unsigned short regId):
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
        if (not segId and not (segId in CPU_REGISTER_SREG)):
            self.main.exitError("segRead: segId is not a segment! ({0:d})", segId)
            return 0
        segId = ((segId//5)<<3)
        # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        segId = self.regs.csReadValueUnsignedBE(segId+6, OP_SIZE_WORD)
        return segId
    cdef unsigned short segWrite(self, unsigned short segId, unsigned short segValue):
        cdef Segment segmentInstance
        if (not segId and not (segId in CPU_REGISTER_SREG)):
            self.main.exitError("segWrite: segId is not a segment! ({0:d})", segId)
            return 0
        if ((<Segments>self.segments).isInProtectedMode()):
            (<Segments>self.segments).checkSegmentLoadAllowed(segValue, segId == CPU_SEGMENT_SS)
        segmentInstance = (<Segment>self.segments.getSegmentInstance(segId))
        segmentInstance.loadSegment(segValue)
        if (segId == CPU_SEGMENT_CS):
            self.codeSegSize = segmentInstance.getSegSize()
            self.eipSizeRegId = (self.codeSegSize == OP_SIZE_DWORD and CPU_REGISTER_EIP) or CPU_REGISTER_IP
        segId = ((segId//5)<<3)
        # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        segValue = self.regs.csWriteValueBE(segId+6, segValue, OP_SIZE_WORD)
        return segValue
    cdef long long regRead(self, unsigned short regId, unsigned char signed): # FIXME
        cdef unsigned char opSize, regOffset
        cdef unsigned short aregId
        if (regId == CPU_REGISTER_NONE):
            return 0
        if (regId < CPU_MIN_REGISTER or regId >= CPU_MAX_REGISTER):
            self.main.exitError("regRead: regId is reserved! ({0:d})", regId)
            return 0
        aregId, regOffset = divmod(regId, 5)
        aregId <<= 3
        if (regOffset == 0):
            opSize = OP_SIZE_QWORD
        elif (regOffset == 2):
            opSize = OP_SIZE_WORD
            aregId += 6
        else:
            aregId += regOffset+3
            if (regOffset == 1):
                opSize = OP_SIZE_DWORD
            else:
                opSize = OP_SIZE_BYTE
        # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        if (signed):
            return self.regs.csReadValueSignedBE(aregId, opSize)
        return self.regs.csReadValueUnsignedBE(aregId, opSize)
    cdef unsigned long regWrite(self, unsigned short regId, unsigned long value):
        cdef unsigned char opSize, regOffset
        cdef unsigned short aregId
        #if (regId < CPU_MIN_REGISTER or regId >= CPU_MAX_REGISTER):
        #    self.main.exitError("regWrite: regId is reserved! ({0:d})", regId)
        #    return 0
        aregId, regOffset = divmod(regId, 5)
        aregId <<= 3
        if (regOffset == 0):
            opSize = OP_SIZE_QWORD
        elif (regOffset == 2):
            opSize = OP_SIZE_WORD
            aregId += 6
        else:
            aregId += regOffset+3
            if (regOffset == 1):
                opSize = OP_SIZE_DWORD
            else:
                opSize = OP_SIZE_BYTE
        # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        value = self.regs.csWriteValueBE(aregId, value, opSize)
        return value # returned value is unsigned!!
    cdef unsigned long regAddReturnOrig(self, unsigned short regId, long long value):
        cdef long long origValue = self.regRead(regId, False)
        self.regWrite(regId, ((origValue+value)&(<Misc>self.main.misc).getBitMaskFF(self.getRegSize(regId))))
        return origValue
    cdef unsigned long regAdd(self, unsigned short regId, long long value):
        return self.regWrite(regId, ((self.regRead(regId, False)+value)&(<Misc>self.main.misc).getBitMaskFF(self.getRegSize(regId))))
    cdef unsigned long regAdc(self, unsigned short regId, unsigned long value):
        return self.regAdd(regId, value+self.getEFLAG( FLAG_CF ))
    cdef unsigned long regSub(self, unsigned short regId, unsigned long value):
        return self.regWrite(regId, ((self.regRead(regId, False)-value)&(<Misc>self.main.misc).getBitMaskFF(self.getRegSize(regId))))
    cdef unsigned long regSbb(self, unsigned short regId, unsigned long value):
        return self.regSub(regId, value+self.getEFLAG( FLAG_CF ))
    cdef unsigned long regXor(self, unsigned short regId, unsigned long value):
        return self.regWrite(regId, (self.regRead(regId, False)^value))
    cdef unsigned long regAnd(self, unsigned short regId, unsigned long value):
        return self.regWrite(regId, (self.regRead(regId, False)&value))
    cdef unsigned long regOr (self, unsigned short regId, unsigned long value):
        return self.regWrite(regId, (self.regRead(regId, False)|value))
    cdef unsigned long regNeg(self, unsigned short regId):
        return self.regWrite(regId, ((-self.regRead(regId, False))&(<Misc>self.main.misc).getBitMaskFF(self.getRegSize(regId))))
    cdef unsigned long regNot(self, unsigned short regId):
        return self.regWrite(regId, ((~self.regRead(regId, False))&(<Misc>self.main.misc).getBitMaskFF(self.getRegSize(regId))))
    cdef unsigned long regWriteWithOp(self, unsigned short regId, unsigned long value, unsigned char valueOp):
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
            value = ((-value)&(<Misc>self.main.misc).getBitMaskFF(self.getRegSize(regId)))
            return self.regWrite(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = ((~value)&(<Misc>self.main.misc).getBitMaskFF(self.getRegSize(regId)))
            return self.regWrite(regId, value)
        else:
            self.main.printMsg("REGISTERS::regWriteWithOp: unknown valueOp {0:d}.", valueOp)
    cdef unsigned long valSetBit(self, unsigned long value, unsigned char bit, unsigned char state):
        if (state):
            return ( value | (1<<bit) )
        return ( value & (~(1<<bit)) )
    cdef unsigned char valGetBit(self, unsigned long value, unsigned char bit): # return True if bit is set, otherwise False
        return (value&(1<<bit))!=0
    cdef unsigned long getEFLAG(self, unsigned long flags):
        return self.getFlag(CPU_REGISTER_EFLAGS, flags)
    cdef unsigned long setEFLAG(self, unsigned long flags, unsigned char flagState):
        if (flagState):
            return self.regOr(CPU_REGISTER_EFLAGS, flags)
        return self.regAnd(CPU_REGISTER_EFLAGS, (~flags)&BITMASK_DWORD)
    cdef unsigned long getFlag(self, unsigned short regId, unsigned long flags):
        return (self.regRead(regId, False)&flags)
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
    cdef setSZP(self, unsigned long value, unsigned char regSize):
        self.setEFLAG(FLAG_SF, (value&(<Misc>self.main.misc).getBitMask80(regSize))!=0)
        self.setEFLAG(FLAG_ZF, value==0)
        self.setEFLAG(FLAG_PF, PARITY_TABLE[value&BITMASK_BYTE])
    cdef setSZP_O0(self, unsigned long value, unsigned char regSize):
        self.setSZP(value, regSize)
        self.setEFLAG(FLAG_OF, False)
    cdef setSZP_C0_O0_A0(self, unsigned long value, unsigned char regSize):
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
                else:
                    if (reg in (4, 5)):
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
        elif (index == 0x2): # C
            return self.getEFLAG(FLAG_CF)!=0
        elif (index == 0x3): # NC
            return self.getEFLAG(FLAG_CF)==0
        elif (index == 0x4): # E
            return self.getEFLAG(FLAG_ZF)!=0
        elif (index == 0x5): # NE
            return self.getEFLAG(FLAG_ZF)==0
        elif (index == 0x6): # NA
            return self.getEFLAG(FLAG_CF_ZF)!=0
        elif (index == 0x7): # A
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
        elif (index == 0xe): # NG
            return (self.getEFLAG(FLAG_ZF)!=0 or (self.getEFLAG(FLAG_SF_OF) in (FLAG_SF, FLAG_OF)) )
        elif (index == 0xf): # G
            return (self.getEFLAG(FLAG_SF_OF_ZF) in (0, FLAG_SF_OF))
        else:
            self.main.exitError("getCond: index {0:#x} invalid.", index)
    cdef setFullFlags(self, long long reg0, long long reg1, unsigned char regSize, unsigned char method, unsigned char signed):
        cdef unsigned char unsignedOverflow, signedOverflow, isResZero, afFlag, reg0Nibble, reg1Nibble, regSumNibble
        cdef unsigned long bitMask, bitMaskHalf
        cdef unsigned long long doubleBitMask, regSumu, regSumMasked, regSumuMasked
        cdef long long regSum
        unsignedOverflow = False
        signedOverflow = False
        isResZero = False
        afFlag = False
        bitMask = (<Misc>self.main.misc).getBitMaskFF(regSize)
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(regSize)

        if (method == OPCODE_ADD or method == OPCODE_ADC):
            if (method == OPCODE_ADC and self.getEFLAG(FLAG_CF)!=0):
                reg0 += 1
            regSum = reg0+reg1
            regSumMasked = regSum&bitMask
            isResZero = regSumMasked==0
            unsignedOverflow = (regSumMasked < reg0 or regSumMasked < reg1)
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&BITMASK_BYTE])
            self.setEFLAG(FLAG_ZF, isResZero)
            reg0Nibble = reg0&0xf
            reg1Nibble = reg1&0xf
            regSumNibble = regSum&0xf
            if ( (((reg0Nibble)+(reg1Nibble))>regSumNibble) or reg0>bitMask or reg1>bitMask):
                afFlag = True
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSum &= bitMaskHalf
            signedOverflow = ( ((not reg0 and not reg1) and regSum) or ((reg0 and reg1) and not regSum) )!=False
            self.setEFLAG(FLAG_AF, afFlag)
            self.setEFLAG(FLAG_CF, unsignedOverflow)
            self.setEFLAG(FLAG_OF, (not isResZero and signedOverflow))
            self.setEFLAG(FLAG_SF, regSum!=0)
        elif (method == OPCODE_SUB or method == OPCODE_SBB):
            if (method == OPCODE_SBB and self.getEFLAG(FLAG_CF)!=0):
                reg0 -= 1
            regSum = reg0-reg1
            regSumMasked = regSum&bitMask
            isResZero = regSumMasked==0
            unsignedOverflow = ( regSum<0 )
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&BITMASK_BYTE])
            self.setEFLAG(FLAG_ZF, isResZero)
            reg0Nibble = reg0&0xf
            reg1Nibble = reg1&0xf
            regSumNibble = regSum&0xf
            if ( ((reg0Nibble-reg1Nibble) < regSumNibble) and reg1!=0):
                afFlag = True
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSum &= bitMaskHalf
            signedOverflow = ( ((reg0 and not reg1) and not regSum) or ((not reg0 and reg1) and regSum) )!=False
            self.setEFLAG(FLAG_AF, afFlag)
            self.setEFLAG(FLAG_CF, unsignedOverflow )
            self.setEFLAG(FLAG_OF, (not isResZero and signedOverflow))
            self.setEFLAG(FLAG_SF, regSum!=0)
        elif (method == OPCODE_MUL):
            doubleBitMask = (<Misc>self.main.misc).getBitMaskFF(regSize<<1)
            regSum = reg0*reg1
            regSumu = abs(reg0)*abs(reg1)
            isResZero = (regSum&doubleBitMask)==0
            signedOverflow = not ((signed and ((regSize != OP_SIZE_BYTE and regSumu <= bitMask) or (regSize == OP_SIZE_BYTE and regSumu <= 0x7f))) or \
                   (not signed and ((regSumu <= bitMask))))
            self.setEFLAG(FLAG_CF | FLAG_OF, signedOverflow)
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&BITMASK_BYTE])
            self.setEFLAG(FLAG_ZF, isResZero)
            self.setEFLAG(FLAG_SF, (regSum&bitMaskHalf)!=0)
    #cdef checkMemAccessRights(self, unsigned short segId, unsigned char write):
    #    cdef unsigned short segVal
    #    if (not self.segments.isInProtectedMode()):
    #        return
    #    segVal = self.segRead(segId)
    #    if (not self.segments.isSegPresent(segVal) ):
    #        if (segId == CPU_SEGMENT_SS):
    #            raise ChemuException(CPU_EXCEPTION_SS, segVal)
    #        else:
    #            raise ChemuException(CPU_EXCEPTION_NP, segVal)
    #    if ( segVal == 0 ):
    #        if (segId == CPU_SEGMENT_SS):
    #            raise ChemuException(CPU_EXCEPTION_SS, segVal)
    #        else:
    #            raise ChemuException(CPU_EXCEPTION_GP, segVal)
    #    if (write):
    #        if (self.segments.isCodeSeg(segVal) or not self.segments.isSegReadableWritable(segVal) ):
    #            if (segId == CPU_SEGMENT_SS):
    #                raise ChemuException(CPU_EXCEPTION_SS, segVal)
    #            else:
    #                raise ChemuException(CPU_EXCEPTION_GP, segVal)
    #    else:
    #        if (self.segments.isCodeSeg(segVal) and not self.segments.isSegReadableWritable(segVal) ):
    #            raise ChemuException(CPU_EXCEPTION_GP, segVal)
    cdef unsigned long getRealAddr(self, unsigned short segId, long long offsetAddr):
        cdef unsigned long realAddr
        realAddr = (<unsigned long>((<Segment>self.segments.getSegmentInstance(segId)).base)+offsetAddr)
        # TODO: check for limit asf...
        if (not self.segments.isInProtectedMode()):
            if (self.segments.getA20State()): # A20 Active? if True == on, else off
                return realAddr&0x1fffff
            return realAddr&0xfffff
        return realAddr
    cdef unsigned long mmGetRealAddr(self, long long mmAddr, unsigned short segId, unsigned char allowOverride):
        if (allowOverride and self.segmentOverridePrefix):
            segId = self.segmentOverridePrefix
        mmAddr = self.getRealAddr(segId, mmAddr)
        return mmAddr
    cdef bytes mmRead(self, long long mmAddr, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(segId, False) # TODO
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyRead(mmAddr, dataSize)
    cdef long long mmReadValueSigned(self, long long mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride):
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueSigned(mmAddr, dataSize)
    cdef unsigned long long mmReadValueUnsigned(self, long long mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride):
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return (<Mm>self.main.mm).mmPhyReadValueUnsigned(mmAddr, dataSize)
    cdef mmWrite(self, long long mmAddr, bytes data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride):
        #self.checkMemAccessRights(segId, True) # TODO
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        (<Mm>self.main.mm).mmPhyWrite(mmAddr, data, dataSize)
    cdef unsigned long long mmWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride):
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        data &= (<Misc>self.main.misc).getBitMaskFF(dataSize)
        return (<Mm>self.main.mm).mmPhyWriteValue(mmAddr, data, dataSize)
    cdef unsigned long long mmWriteValueWithOp(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride, unsigned char valueOp):
        cdef unsigned char carryOn
        cdef unsigned long long oldData, bitMask
        if (valueOp == OPCODE_SAVE):
            return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
        else:
            bitMask = (<Misc>self.main.misc).getBitMaskFF(dataSize)
            if (valueOp == OPCODE_NEG):
                data = (-data)&bitMask
                return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
            elif (valueOp == OPCODE_NOT):
                data = (~data)&bitMask
                return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
            else:
                oldData = self.mmReadValueUnsigned(mmAddr, dataSize, segId, allowOverride)
                if (valueOp == OPCODE_ADD):
                    data = (oldData+data)&bitMask
                    return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
                elif (valueOp in (OPCODE_ADC, OPCODE_SBB)):
                    carryOn = self.getEFLAG( FLAG_CF )!=0
                    if (valueOp == OPCODE_ADC):
                        data = (oldData+(data+carryOn))&bitMask
                    else:
                        data = (oldData-(data+carryOn))&bitMask
                    return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
                elif (valueOp == OPCODE_SUB):
                    data = (oldData-data)&bitMask
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
        return (<Segment>self.segments.getSegmentInstance(segId)).getSegSize()
    cdef unsigned char isSegPresent(self, unsigned short segId):
        return (((<Segment>self.segments.getSegmentInstance(segId)).accessByte & GDT_ACCESS_PRESENT) != 0)
    cdef unsigned char getOpSegSize(self, unsigned short segId):
        segId  = self.getSegSize(segId)
        opSize = (((segId==OP_SIZE_WORD)==self.operandSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD
        return opSize
    cdef unsigned char getAddrSegSize(self, unsigned short segId):
        segId    = self.getSegSize(segId)
        addrSize = (((segId==OP_SIZE_WORD)==self.addressSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD
        return addrSize
    cdef getOpAddrSegSize(self, unsigned short segId, unsigned char *opSize, unsigned char *addrSize):
        segId    = self.getSegSize(segId)
        opSize[0]   = (((segId==OP_SIZE_WORD)==self.operandSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD
        addrSize[0] = (((segId==OP_SIZE_WORD)==self.addressSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD
    cdef unsigned char getOpCodeSegSize(self):
        opSize = (((self.codeSegSize==OP_SIZE_WORD)==self.operandSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD
        return opSize
    cdef unsigned char getAddrCodeSegSize(self):
        addrSize = (((self.codeSegSize==OP_SIZE_WORD)==self.addressSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD
        return addrSize
    cdef getOpAddrCodeSegSize(self, unsigned char *opSize, unsigned char *addrSize):
        opSize[0]   = (((self.codeSegSize==OP_SIZE_WORD)==self.operandSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD
        addrSize[0] = (((self.codeSegSize==OP_SIZE_WORD)==self.addressSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD
    cdef run(self):
        self.regs = ConfigSpace(CPU_REGISTER_LENGTH, self.main)
        self.segments = Segments(self.main)
        self.regs.run()
        self.segments.run()


