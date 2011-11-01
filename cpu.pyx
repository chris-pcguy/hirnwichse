import struct, time, sys, threading

import registers, opcodes, misc
include "globals.pxi"


##DEF TICKS_PER_CYCLE = 2000
DEF TICK_BITMASK  = 0xffffffffffffffff

cdef class Cpu:
    def __init__(self, object main):
        self.main = main
        self.registers = registers.Registers(self.main, self)
        self.opcodes = opcodes.Opcodes(self.main, self)
    cpdef reset(self):
        self.savedCs  = 0
        self.savedEip = 0
        self.cpuHalted = False
        self.debugHalt = False
        self.debugSingleStep = False
        self.cycles = 0
        self.oldCycles = 0
        self.A20Active = False
        self.protectedModeOn = False
        self.HRQ = False
        self.registers.reset()
    cpdef unsigned char getA20State(self):
        return self.A20Active
    cpdef setA20State(self, unsigned char state):
        self.A20Active = state
    cpdef setHRQ(self, unsigned char state):
        self.HRQ = state
        if (state):
            self.asyncEvent = True
    cpdef setIrq(self, unsigned char state):
        self.irqEvent = state
        self.asyncEvent = True
    cpdef unsigned long long getCurrentOpcodeAddr(self):
        cdef unsigned char eipSize
        cdef unsigned short eipSizeRegId
        cdef unsigned long long opcodeAddr
        eipSize = self.registers.segments.getSegSize(CPU_SEGMENT_CS)
        eipSizeRegId = self.registers.getWordAsDword(CPU_REGISTER_IP, eipSize)
        opcodeAddr = self.registers.segments.getRealAddr(CPU_SEGMENT_CS, self.registers.regRead(eipSizeRegId, False))
        return opcodeAddr
    cpdef long long getCurrentOpcode(self, unsigned char numBytes, unsigned char signed): # numBytes in bytes
        cdef unsigned long opcodeAddr = self.getCurrentOpcodeAddr()
        cdef long long currentOpcode = self.main.mm.mmPhyReadValue(opcodeAddr, numBytes, signed)
        return currentOpcode
    cpdef long long getCurrentOpcodeAdd(self, unsigned char numBytes, unsigned char signed): # numBytes in bytes
        cdef long long currentOpcode = self.getCurrentOpcode(numBytes, signed)
        cdef unsigned char operSize   = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef unsigned short regSizeId  = self.registers.getWordAsDword(CPU_REGISTER_IP, operSize)
        self.registers.regAdd(regSizeId, numBytes)
        return currentOpcode
    cpdef tuple getCurrentOpcodeWithAddr(self, unsigned char getAddr, unsigned char numBytes, unsigned char signed): # numBytes in bytes
        cdef unsigned long opcodeAddr = self.getCurrentOpcodeAddr()
        cdef long long currentOpcode = self.main.mm.mmPhyReadValue(opcodeAddr, numBytes, signed)
        if (getAddr == GETADDR_OPCODE):
            return currentOpcode, opcodeAddr
        elif (getAddr == GETADDR_NEXT_OPCODE):
            return currentOpcode, opcodeAddr+numBytes
        else:
            self.main.exitError("CPU::getCurrentOpcodeWithAddr: getAddr {0:d} unknown.", getAddr)
    cpdef tuple getCurrentOpcodeAddWithAddr(self, unsigned char getAddr, unsigned char numBytes, unsigned char signed): # numBytes in bytes
        cdef tuple opcodeData = self.getCurrentOpcodeWithAddr(getAddr, numBytes, signed)
        cdef unsigned char operSize   = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef unsigned short regSizeId  = self.registers.getWordAsDword(CPU_REGISTER_IP, operSize)
        self.registers.regAdd(regSizeId, numBytes)
        return opcodeData
    cpdef unsigned char handleAsyncEvent(self): # return True if irq was handled, otherwise False
        cdef unsigned char irqVector
        if (self.asyncEvent): # This is only for IRQs! (exceptions will use cpu.exception)
            if (self.irqEvent and self.registers.getEFLAG(FLAG_IF) ):
                self.setIrq(False)
                irqVector = self.main.platform.pic.IAC()
                self.opcodes.interrupt(irqVector, -1, True)
                self.asyncEvent = False
                return True
        return False
    cpdef exception(self, unsigned char exceptionId, long errorCode):
        ##if (exceptionId in CPU_EXCEPTIONS_FAULT_GROUP):
        if (exceptionId in CPU_EXCEPTIONS_TRAP_GROUP):
            self.savedEip += 1
        self.registers.segWrite(CPU_SEGMENT_CS, self.savedCs)
        self.registers.regWrite(CPU_REGISTER_EIP, self.savedEip)
        if (exceptionId in CPU_EXCEPTIONS_WITH_ERRORCODE):
            if (errorCode == -1):
                self.main.exitError("CPU exception: errorCode should be set, is -1.")
                return
            self.opcodes.interrupt(exceptionId, errorCode, True)
            return
        self.opcodes.interrupt(exceptionId, -1, True)
    cpdef handleException(self, object exception):
        cdef unsigned char exceptionId
        cdef long errorCode
        if (len(exception.args) not in (1, 2)):
            self.main.exitError('ERROR: exception argument length not in (1, 2); is {0:d}', len(exception.args), exitNow=True)
            return
        errorCode = -1
        if (len(exception.args) == 2):
            if (not isinstance(exception.args[1], int)):
                self.main.exitError('ERROR: errorCode not a int; type is {0:s}', type(exception.args[1]), exitNow=True)
                return
            errorCode = exception.args[1]
        if (not isinstance(exception.args[0], int)):
            self.main.exitError('ERROR: exceptionId not a int; type is {0:s}', type(exception.args[0]), exitNow=True)
            return
        exceptionId = exception.args[0]
        if (exceptionId == CPU_EXCEPTION_UD):
            self.main.printMsg("CPU::handleException: UD: Opcode not found. (opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x})", self.opcode, self.savedEip, self.savedCs)
        else:
            self.main.printMsg("CPU::handleException: Handle exception {0:d}. (opcode: {1:#04x}; EIP: {2:#06x}, CS: {3:#06x})", exceptionId, self.opcode, self.savedEip, self.savedCs)
        self.exception(exceptionId, errorCode)
    cpdef unsigned char isInProtectedMode(self):
        return self.protectedModeOn
    cpdef unsigned char parsePrefixes(self, unsigned char opcode):
        cdef unsigned char count = 0
        while (opcode in OPCODE_PREFIXES):
            count += 1
            if (count >= 16):
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            if (opcode == OPCODE_PREFIX_LOCK):
                self.registers.lockPrefix = True
            #elif (opcode in OPCODE_PREFIX_BRANCHES):
            #    self.registers.branchPrefix = opcode
            elif (opcode in OPCODE_PREFIX_REPS):
                self.registers.repPrefix = opcode
            elif (opcode in OPCODE_PREFIX_SEGMENTS):
                if (opcode == OPCODE_PREFIX_CS):
                    segId = CPU_SEGMENT_CS
                elif (opcode == OPCODE_PREFIX_DS):
                    segId = CPU_SEGMENT_DS
                elif (opcode == OPCODE_PREFIX_ES):
                    segId = CPU_SEGMENT_ES
                elif (opcode == OPCODE_PREFIX_FS):
                    segId = CPU_SEGMENT_FS
                elif (opcode == OPCODE_PREFIX_GS):
                    segId = CPU_SEGMENT_GS
                elif (opcode == OPCODE_PREFIX_SS):
                    segId = CPU_SEGMENT_SS
                else:
                    self.main.exitError("parsePrefixes: {0:#04x} not a segment prefix.", opcode)
                    return 0
                self.registers.segmentOverridePrefix = segId
            elif (opcode == OPCODE_PREFIX_OP):
                self.registers.operandSizePrefix = True
            elif (opcode == OPCODE_PREFIX_ADDR):
                self.registers.addressSizePrefix = True
            
            opcode = self.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        
        return opcode
    cpdef doInfiniteCycles(self):
        while (not self.main.quitEmu):
            if ((self.cpuHalted and self.main.exitIfCpuHalted) or self.main.quitEmu):
                #break
                return
            elif ((self.cpuHalted and not self.main.exitIfCpuHalted) or (self.debugHalt and not self.debugSingleStep)):
                self.handleAsyncEvent()
                if (self.main.platform.vga.ui):
                    self.main.platform.vga.ui.handleEvents()
                time.sleep(1)
                continue
            ## handle gui events: BEGIN
            if (not (self.cycles % 200) and self.main.platform.vga.ui):
                self.main.platform.vga.ui.handleEvents()
            ## handle gui events: END
            self.doCycle()
    cpdef doCycle(self):
        ##cpdef object opcodeHandle
        if (self.cpuHalted or self.main.quitEmu or (self.debugHalt and not self.debugSingleStep)):
            return
        if (self.debugHalt and self.debugSingleStep):
            self.debugSingleStep = False
        #self.cycles = (self.cycles+(1*TICKS_PER_CYCLE))&TICK_BITMASK
        self.cycles = (self.cycles+1)&TICK_BITMASK
        self.registers.resetPrefixes()
        self.savedCs  = self.registers.segRead(CPU_SEGMENT_CS)
        self.savedEip = self.registers.regRead(CPU_REGISTER_EIP, False)
        self.handleAsyncEvent()
        self.opcode = self.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        if (self.opcode in OPCODE_PREFIXES):
            self.opcode = self.parsePrefixes(self.opcode)
        self.main.debug("Current Opcode: {0:#04x}; It's EIP: {1:#06x}, CS: {2:#06x}", self.opcode, self.savedEip, self.savedCs)
        ##opcodeHandle = self.opcodes.opcodeList.get(self.opcode)
        try:
            if (self.registers.lockPrefix and self.opcode in OPCODES_LOCK_PREFIX_INVALID):
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            elif (not self.opcodes.executeOpcode(self.opcode)):
                self.main.printMsg("Opcode not found. (opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x})", self.opcode, self.savedEip, self.savedCs)
                raise misc.ChemuException(CPU_EXCEPTION_UD)
        except misc.ChemuException as exception: # exception
            try:
                self.handleException(exception) # execute exception handler
            except misc.ChemuException as exception: # DF double fault
                try:
                    raise misc.ChemuException(CPU_EXCEPTION_DF, 0) # exec DF double fault
                except misc.ChemuException as exception:
                    try:
                        self.handleException(exception) # handle DF double fault
                    except misc.ChemuException as exception: # DF double fault failed! triple fault... reset!
                        if (self.main.exitOnTripleFault):
                            self.main.exitError("CPU::doCycle: TRIPLE FAULT! exit.", exitNow=True)
                        else:
                            self.main.printMsg("CPU::doCycle: TRIPLE FAULT! reset.")
                            self.cpu.reset()
        except:
            print(sys.exc_info())
            self.main.exitError('doCycle: exception while in opcodeHandle, exiting... (opcode: {0:#04x})', self.opcode, exitNow=True)    
    cpdef runCDEF(self):
        self.reset()
        ###self.misc.createThread(self.doInfiniteCycles, True)
        self.doInfiniteCycles()
    cpdef run(self):
        self.runCDEF()


