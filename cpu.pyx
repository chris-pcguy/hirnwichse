import struct, time

import chemu
import registers, opcodes, misc



cdef class Cpu:
    #cdef object main
    #cdef object registers
    #cdef object opcodes
    #cdef object main, registers, opcodes
    def __init__(self, object main):
        self.main = main
        self.registers = registers.Registers(self.main, self)
        self.opcodes = opcodes.Opcodes(self.main, self)
        self.reset()
    cpdef reset(self):
        self.savedCs  = 0
        self.savedEip = 0
        self.cpuHalted = False
    cpdef getCurrentOpcodeAddr(self):
        cpdef int eipSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int eipSizeRegId = registers.CPU_REGISTER_IP
        cpdef long opcodeAddr = 0
        if (eipSize not in (misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT)):
            self.main.exitError("eipSize is INVALID. ({0:d})", eipSize)
        elif (eipSize == misc.OP_SIZE_32BIT):
            eipSizeRegId = registers.CPU_REGISTER_EIP
        opcodeAddr = self.registers.segments.getRealAddr(registers.CPU_SEGMENT_CS, self.registers.regRead(eipSizeRegId))
        ##opcodeAddr += self.registers.regRead(eipSizeId)
        return opcodeAddr
    cpdef getCurrentOpcode(self, int numBytes=1, int signed=False):
        cpdef long eip = self.getCurrentOpcodeAddr()
        cpdef long currentOpcode = 0
        return currentOpcode.from_bytes(bytes=self.main.mm.mmRead(eip, numBytes, segId=0), byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=signed)
    cpdef getCurrentOpcodeAdd(self, int numBytes=1, int signed=False): # numBytes in bytes
        cpdef long opcodeData = self.getCurrentOpcode(numBytes, signed)
        cpdef int regSizeId = registers.CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS) == misc.OP_SIZE_32BIT):
            regSizeId = registers.CPU_REGISTER_EIP
        self.registers.regAdd(regSizeId, numBytes)
        return opcodeData
    cpdef getCurrentOpcodeAddEip(self, int signed=False):
        cpdef int regSize   = 2
        cpdef int regSizeId = registers.CPU_REGISTER_IP
        cpdef long opcodeData = 0
        if (self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS) == misc.OP_SIZE_32BIT):
            regSize   = 4
            regSizeId = registers.CPU_REGISTER_EIP
        opcodeData = self.getCurrentOpcode(regSize, signed)
        self.registers.regAdd(regSizeId, regSize)
        return opcodeData
    cpdef exception(self, int exceptionId):
        self.main.exitError("CPU Exception catched. (exceptionId: {0:d})", exceptionId)
    cpdef parsePrefixes(self, int opcode):
        while (opcode in misc.OPCODE_PREFIXES):
            if (opcode == misc.OPCODE_PREFIX_LOCK):
                self.registers.lockPrefix = True
            elif (opcode in misc.OPCODE_PREFIX_BRANCHES):
                self.registers.branchPrefix = opcode
            elif (opcode in misc.OPCODE_PREFIX_REPS):
                self.registers.repPrefix = opcode
            elif (opcode in misc.OPCODE_PREFIX_SEGMENTS):
                self.registers.segmentOverridePrefix = opcode
            elif (opcode == misc.OPCODE_PREFIX_OP):
                self.registers.operandSizePrefix = True
            elif (opcode == misc.OPCODE_PREFIX_ADDR):
                self.registers.addressSizePrefix = True
            
            opcode = self.getCurrentOpcodeAdd()
        
        return opcode
    cpdef doInfiniteCycles(self):
        while True:
            if (self.cpuHalted and not self.main.exitIfCpuHalted):
                time.sleep(0.5)
            elif (self.cpuHalted and self.main.exitIfCpuHalted):
                break
            self.doCycle()
    cpdef doCycle(self):
        if (self.cpuHalted): return None
        self.registers.resetPrefixes()
        self.savedCs  = self.registers.regRead(registers.CPU_SEGMENT_CS)
        self.savedEip = self.registers.regRead(registers.CPU_REGISTER_EIP)
        self.savedAddr = self.registers.segments.getRealAddr(registers.CPU_SEGMENT_CS,self.savedEip)
        self.opcode = self.getCurrentOpcodeAdd()
        
        self.main.debug("Current Opcode: {0:#04x}; It's Addr: {1:#010x}", self.opcode, self.savedAddr)
        if (self.opcode in misc.OPCODE_PREFIXES):
            self.opcode = self.parsePrefixes(self.opcode)
        
        if (self.opcode in self.opcodes.opcodeList):
            self.opcodes.opcodeList[self.opcode]()
        else:
            self.main.debug("Opcode not found. (opcode: {0:#04x}; addr: {1:#07x})", self.opcode, self.savedAddr)
            self.exception(misc.CPU_EXCEPTION_UD)
    cpdef run(self):
        self.doInfiniteCycles()



