import struct, time, sys, threading, _thread

###import chemu
import registers, opcodes, misc



cdef class Cpu:
    cdef public object main, registers, opcodes
    cdef public unsigned long long opcode, cycles
    cdef public unsigned char cpuHalted, debugHalt, debugSingleStep, A20Active, protectedModeOn
    cdef unsigned char asyncEvent
    cdef short intrNum
    cdef unsigned long long savedCs, savedEip
    def __init__(self, object main):
        self.main = main
        self.registers = registers.Registers(self.main, self)
        self.opcodes = opcodes.Opcodes(self.main, self)
        self.reset()
    def reset(self):
        self.savedCs  = 0
        self.savedEip = 0
        self.cpuHalted = False
        self.debugHalt = False
        self.debugSingleStep = False
        self.cycles = 0
        self.A20Active = False
        self.protectedModeOn = False
        self.registers.reset()
    def getA20State(self):
        return self.A20Active
    def setA20State(self, int state):
        self.A20Active = state
    def setIntr(self, unsigned char intrNum):
        self.intrNum = intrNum
        self.asyncEvent = True
    def getCurrentOpcodeAddr(self):
        cdef unsigned char eipSize
        cdef unsigned short eipSizeRegId
        cdef unsigned long long opcodeAddr
        eipSize = self.registers.segments.getSegSize(registers.CPU_SEGMENT_CS)
        eipSizeRegId = self.registers.getWordAsDword(registers.CPU_REGISTER_IP, eipSize)
        opcodeAddr = self.registers.segments.getRealAddr(registers.CPU_SEGMENT_CS, self.registers.regRead(eipSizeRegId))
        return opcodeAddr
    def getCurrentOpcode(self, unsigned char numBytes=1, unsigned char signed=False): # numBytes in bytes
        cdef unsigned long opcodeAddr = self.getCurrentOpcodeAddr()
        cdef long long currentOpcode = self.main.mm.mmPhyReadValue(opcodeAddr, numBytes, signed=signed)
        return currentOpcode
    def getCurrentOpcodeAdd(self, unsigned char numBytes=1, unsigned char signed=False): # numBytes in bytes
        cdef long long currentOpcode = self.getCurrentOpcode(numBytes, signed=signed)
        cdef unsigned char operSize   = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef unsigned short regSizeId  = self.registers.getWordAsDword(registers.CPU_REGISTER_IP, operSize)
        self.registers.regAdd(regSizeId, numBytes)
        return currentOpcode
    def getCurrentOpcodeWithAddr(self, unsigned char getAddr, unsigned char numBytes=1, unsigned char signed=False): # numBytes in bytes
        cdef unsigned long opcodeAddr = self.getCurrentOpcodeAddr()
        cdef long long currentOpcode = self.main.mm.mmPhyReadValue(opcodeAddr, numBytes, signed=signed)
        if (getAddr == misc.GETADDR_OPCODE):
            return currentOpcode, opcodeAddr
        elif (getAddr == misc.GETADDR_NEXT_OPCODE):
            return currentOpcode, opcodeAddr+numBytes
    def getCurrentOpcodeAddWithAddr(self, unsigned char getAddr, unsigned char numBytes=1, unsigned char signed=False): # numBytes in bytes
        cdef tuple opcodeData = self.getCurrentOpcodeWithAddr(getAddr, numBytes, signed=signed)
        cdef unsigned char operSize   = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef unsigned short regSizeId  = self.registers.getWordAsDword(registers.CPU_REGISTER_IP, operSize)
        self.registers.regAdd(regSizeId, numBytes)
        return opcodeData
    def exception(self, unsigned char exceptionId, long errorCode=-1):
        if (exceptionId in misc.CPU_EXCEPTIONS_FAULT_GROUP):
            self.registers.segWrite(registers.CPU_SEGMENT_CS, self.savedCs)
            self.registers.regWrite(registers.CPU_REGISTER_EIP, self.savedEip)
        if (exceptionId in misc.CPU_EXCEPTIONS_WITH_ERRORCODE):
            if (errorCode == -1):
                self.main.exitError("CPU exception: errorCode should be set, is -1.")
                return
            self.opcodes.interrupt(exceptionId, errorCode=errorCode)
            return
        self.opcodes.interrupt(exceptionId)
    def isInProtectedMode(self):
        return self.protectedModeOn
    def parsePrefixes(self, unsigned char opcode):
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
                    return
                self.registers.segmentOverridePrefix = segId
            elif (opcode == misc.OPCODE_PREFIX_OP):
                self.registers.operandSizePrefix = True
            elif (opcode == misc.OPCODE_PREFIX_ADDR):
                self.registers.addressSizePrefix = True
            
            opcode = self.getCurrentOpcodeAdd()
        
        return opcode
    def doInfiniteCycles(self):
        #try:
        while (not self.main.quitEmu):
            if ((self.cpuHalted and self.main.exitIfCpuHalted) or self.main.quitEmu):
                #break
                return
            elif ((self.cpuHalted and not self.main.exitIfCpuHalted) or (self.debugHalt and not self.debugSingleStep)):
                time.sleep(1)
                continue
            self.doCycle()
        #except KeyboardInterrupt:
        #    sys.exit(1)
        #finally:
        #    sys.exit(0)
    def doCycle(self):
        cdef object opcodeHandle
        if (self.cpuHalted or self.main.quitEmu or (self.debugHalt and not self.debugSingleStep)):
            return
        if (self.debugHalt and self.debugSingleStep):
            self.debugSingleStep = False
        self.cycles += 1
        self.registers.resetPrefixes()
        self.savedCs  = self.registers.segRead(registers.CPU_SEGMENT_CS)
        self.savedEip = self.registers.regRead(registers.CPU_REGISTER_EIP)
        if (self.asyncEvent):
            if (self.intrNum != -1 and self.registers.getEFLAG(registers.FLAG_IF) ):
                self.main.platform.pic.handleIrq(self.intrNum)
                self.intrNum = -1
                self.asyncEvent = False
                return
        self.opcode = self.getCurrentOpcodeAdd(misc.OP_SIZE_BYTE)
        if (self.opcode in misc.OPCODE_PREFIXES):
            self.opcode = self.parsePrefixes(self.opcode)
        self.main.debug("Current Opcode: {0:#04x}; It's EIP: {1:#06x}, CS: {2:#06x}", self.opcode, self.savedEip, self.savedCs)
        opcodeHandle = self.opcodes.opcodeList.get(self.opcode)
        if (opcodeHandle):
            try:
                opcodeHandle()
            except:
                print(sys.exc_info())
                #_thread.exit()
                self.main.exitError('doCycle: exception while in opcodeHandle, exiting... (opcode: {0:#04x})', self.opcode, exitNow=True)
        else:
            self.main.printMsg("Opcode not found. (opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x})", self.opcode, self.savedEip, self.savedCs)
            self.exception(misc.CPU_EXCEPTION_UD)
            ##sys.exit(1) # TODO!!!
            self.main.exitError('TODO: opcode not found, exiting...', exitNow=True)
    def run(self):
        self.doInfiniteCycles()



