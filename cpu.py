import struct, time

import chemu
import registers, opcodes, misc



class Cpu:
    #cdef object main
    #cdef object registers
    #cdef object opcodes
    #cdef object main, registers, opcodes
    def __init__(self, main):
        self.main = main
        self.registers = registers.Registers(self.main, self)
        self.opcodes = opcodes.Opcodes(self.main, self)
        self.reset()
    def reset(self):
        self.savedCs  = 0
        self.savedEip = 0
        self.cpuHalted = False
    def getCurrentOpcodeAddr(self):
        eipSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        eipSizeRegId = registers.CPU_REGISTER_IP
        opcodeAddr = 0
        if (eipSize not in (misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT)):
            self.main.exitError("eipSize is INVALID. ({0:d})", eipSize)
        elif (eipSize == misc.OP_SIZE_32BIT):
            eipSizeRegId = registers.CPU_REGISTER_EIP
        opcodeAddr = self.registers.segments.getRealAddr(registers.CPU_SEGMENT_CS, self.registers.regRead(eipSizeRegId))
        ##opcodeAddr += self.registers.regRead(eipSizeId)
        return opcodeAddr
    def getCurrentOpcode(self, numBytes=1, signed=False):
        eip = self.getCurrentOpcodeAddr()
        currentOpcode = 0
        return self.main.mm.mmPhyReadValue(eip, numBytes, signed=signed)
    def getCurrentOpcodeAdd(self, numBytes=1, signed=False): # numBytes in bytes
        opcodeData = self.getCurrentOpcode(numBytes, signed=signed)
        regSizeId = registers.CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS) == misc.OP_SIZE_32BIT):
            regSizeId = registers.CPU_REGISTER_EIP
        self.registers.regAdd(regSizeId, numBytes)
        return opcodeData
    def getCurrentOpcodeAddEip(self, signed=False):
        regSize   = 2
        regSizeId = registers.CPU_REGISTER_IP
        opcodeData = 0
        if (self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS) == misc.OP_SIZE_32BIT):
            regSize   = 4
            regSizeId = registers.CPU_REGISTER_EIP
        opcodeData = self.getCurrentOpcode(regSize, signed)
        self.registers.regAdd(regSizeId, regSize)
        return opcodeData
    def exception(self, exceptionId):
        ####self.main.exitError("CPU Exception catched. (exceptionId: {0:d})", exceptionId)
        self.registers.regWrite(registers.CPU_SEGMENT_CS, self.savedCs)
        self.registers.regWrite(registers.CPU_REGISTER_EIP, self.savedEip)
        self.opcodes.interrupt(exceptionId)
        ##self.opcodes.stackPushValue(0, misc.OP_SIZE_16BIT)
        ##self.opcodes.stackPushValue(self.savedCs, misc.OP_SIZE_16BIT)
        ##self.opcodes.stackPushValue(self.savedEip, misc.OP_SIZE_16BIT)
    def parsePrefixes(self, opcode):
        while (opcode in misc.OPCODE_PREFIXES):
            if (opcode == misc.OPCODE_PREFIX_LOCK):
                self.registers.lockPrefix = True
            #elif (opcode in misc.OPCODE_PREFIX_BRANCHES):
            #    self.registers.branchPrefix = opcode
            elif (opcode in misc.OPCODE_PREFIX_REPS):
                self.registers.repPrefix = opcode
            elif (opcode in misc.OPCODE_PREFIX_SEGMENTS):
                if (opcode == misc.OPCODE_PREFIX_CS):
                    segId = registers.CPU_SEGMENT_CS
                elif (opcode == misc.OPCODE_PREFIX_DS):
                    segId = registers.CPU_SEGMENT_DS
                elif (opcode == misc.OPCODE_PREFIX_ES):
                    segId = registers.CPU_SEGMENT_ES
                elif (opcode == misc.OPCODE_PREFIX_FS):
                    segId = registers.CPU_SEGMENT_FS
                elif (opcode == misc.OPCODE_PREFIX_GS):
                    segId = registers.CPU_SEGMENT_GS
                elif (opcode == misc.OPCODE_PREFIX_SS):
                    segId = registers.CPU_SEGMENT_SS
                else:
                    self.main.exitError("parsePrefixes: {0:#04x} not a segment prefix.", opcode)
                self.registers.segmentOverridePrefix = segId
            elif (opcode == misc.OPCODE_PREFIX_OP):
                self.registers.operandSizePrefix = True
            elif (opcode == misc.OPCODE_PREFIX_ADDR):
                self.registers.addressSizePrefix = True
            
            opcode = self.getCurrentOpcodeAdd()
        
        return opcode
    def doInfiniteCycles(self):
        while True:
            if (self.cpuHalted and not self.main.exitIfCpuHalted):
                time.sleep(0.5)
            elif (self.cpuHalted and self.main.exitIfCpuHalted):
                break
            self.doCycle()
    def doCycle(self):
        if (self.cpuHalted): return None
        self.registers.resetPrefixes()
        self.savedCs  = self.registers.regRead(registers.CPU_SEGMENT_CS)
        self.savedEip = self.registers.regRead(registers.CPU_REGISTER_EIP)
        self.savedAddr = self.getCurrentOpcodeAddr()
        self.opcode = self.getCurrentOpcodeAdd()
        self.main.debug("Current Opcode: {0:#04x}; It's Addr: {1:#010x}", self.opcode, self.savedAddr)
        if (self.opcode in misc.OPCODE_PREFIXES):
            self.opcode = self.parsePrefixes(self.opcode)
        
        ###print(hex(self.registers.regRead(registers.CPU_REGISTER_ESP)))
        
        if (self.opcode in self.opcodes.opcodeList):
            self.opcodes.opcodeList[self.opcode]()
        else:
            self.main.printMsg("Opcode not found. (opcode: {0:#04x}; addr: {1:#07x})", self.opcode, self.savedAddr)
            self.exception(misc.CPU_EXCEPTION_UD)
    def run(self):
        self.doInfiniteCycles()



