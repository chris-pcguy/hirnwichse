
from sys import exit
from time import sleep
from traceback import print_exc
from misc import ChemuException


include "globals.pxi"
include "cpu_globals.pxi"



cdef class Cpu:
    def __init__(self, object main):
        self.main = main
    cdef void reset(self):
        self.savedCs  = 0xf000
        self.savedEip = 0xfff0
        self.cpuHalted = self.debugHalt = self.debugSingleStep = self.INTR = \
          self.HRQ = False
        self.debugHalt = self.main.debugHalt
        self.cycles = self.oldCycleInc = self.exceptionLevel = 0
        self.registers.reset()
    cdef inline void saveCurrentInstPointer(self):
        self.savedCs  = self.registers.segRead(CPU_SEGMENT_CS)
        self.savedEip = self.registers.regReadUnsignedDword(CPU_REGISTER_EIP)
    cdef inline void setINTR(self, unsigned char state):
        self.INTR = state
        self.asyncEvent = True
    cdef inline void setHRQ(self, unsigned char state):
        self.HRQ = state
        if (state):
            self.asyncEvent = True
    cdef void handleAsyncEvent(self):
        cdef unsigned char irqVector, oldIF
        # This is only for IRQs! (exceptions will use cpu.exception)
        oldIF = self.registers.if_flag
        if (self.INTR and oldIF ):
            irqVector = (<Pic>self.main.platform.pic).IAC()
            self.opcodes.interrupt(irqVector, -1)
            ##self.saveCurrentInstPointer() # TODO: do we need this here?
        elif (self.HRQ):
            (<IsaDma>self.main.platform.isadma).raiseHLDA()
        if (not ((self.INTR and oldIF ) or self.HRQ) ):
            self.asyncEvent = False
        return
    cpdef exception(self, unsigned char exceptionId, signed int errorCode):
        self.main.notice("Running exception: exceptionId: {0:#04x}, errorCode: {1:#04x}", exceptionId, errorCode)
        ##if (exceptionId in CPU_EXCEPTIONS_FAULT_GROUP):
        if (exceptionId in CPU_EXCEPTIONS_TRAP_GROUP):
            self.savedEip = <unsigned int>(self.savedEip+1)
        self.registers.segWrite(CPU_SEGMENT_CS, self.savedCs)
        self.registers.regWriteDword(CPU_REGISTER_EIP, self.savedEip)
        if (exceptionId in CPU_EXCEPTIONS_WITH_ERRORCODE):
            if (errorCode == -1):
                self.main.exitError("CPU exception: errorCode should be set, is -1.")
                return
            self.opcodes.interrupt(exceptionId, errorCode)
        else:
            self.opcodes.interrupt(exceptionId, -1)
        self.exceptionLevel = 0
    cpdef handleException(self, object exception):
        cdef unsigned char exceptionId
        cdef signed int errorCode
        if (len(exception.args) not in (1, 2)):
            self.main.exitError('ERROR: exception argument length not in (1, 2); is {0:d}', len(exception.args))
            return
        errorCode = -1
        if (len(exception.args) == 2):
            if (not isinstance(exception.args[1], int)):
                self.main.exitError('ERROR: errorCode not a int; type is {0:s}', type(exception.args[1]))
                return
            errorCode = exception.args[1]
        if (not isinstance(exception.args[0], int)):
            self.main.exitError('ERROR: exceptionId not a int; type is {0:s}', type(exception.args[0]))
            return
        exceptionId = exception.args[0]
        if (exceptionId == CPU_EXCEPTION_UD):
            self.main.notice("CPU::handleException: UD: Opcode not found. (opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x})", self.opcode, self.savedEip, self.savedCs)
        else:
            self.main.notice("CPU::handleException: Handle exception {0:d}. (opcode: {1:#04x}; EIP: {2:#06x}, CS: {3:#06x})", exceptionId, self.opcode, self.savedEip, self.savedCs)
        self.exception(exceptionId, errorCode)
    cdef unsigned char parsePrefixes(self, unsigned char opcode):
        cdef unsigned char count
        count = 0
        while (opcode in OPCODE_PREFIXES and not self.main.quitEmu):
            count += 1
            if (count >= 16):
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (opcode == OPCODE_PREFIX_OP):
                self.registers.operandSizePrefix = True
            elif (opcode == OPCODE_PREFIX_ADDR):
                self.registers.addressSizePrefix = True
            elif (opcode == OPCODE_PREFIX_CS):
                self.registers.segmentOverridePrefix = CPU_SEGMENT_CS
            elif (opcode == OPCODE_PREFIX_SS):
                self.registers.segmentOverridePrefix = CPU_SEGMENT_SS
            elif (opcode == OPCODE_PREFIX_DS):
                self.registers.segmentOverridePrefix = CPU_SEGMENT_DS
            elif (opcode == OPCODE_PREFIX_ES):
                self.registers.segmentOverridePrefix = CPU_SEGMENT_ES
            elif (opcode == OPCODE_PREFIX_FS):
                self.registers.segmentOverridePrefix = CPU_SEGMENT_FS
            elif (opcode == OPCODE_PREFIX_GS):
                self.registers.segmentOverridePrefix = CPU_SEGMENT_GS
            elif (opcode == OPCODE_PREFIX_REPE or opcode == OPCODE_PREFIX_REPNE):
                self.registers.repPrefix = opcode
            ### TODO: I don't think, that we ever need lockPrefix.
            elif (opcode == OPCODE_PREFIX_LOCK):
                self.main.notice("CPU::parsePrefixes: LOCK-prefix is selected! (unimplemented, bad things may happen.)")
            opcode = self.registers.getCurrentOpcodeAddUnsignedByte()
        return opcode
    cpdef cpuDump(self):
        self.main.notice("EAX: {0:#010x}, ECX: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_EAX), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_ECX))
        self.main.notice("EDX: {0:#010x}, EBX: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_EDX), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_EBX))
        self.main.notice("ESP: {0:#010x}, EBP: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_ESP), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_EBP))
        self.main.notice("ESI: {0:#010x}, EDI: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_ESI), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_EDI))
        self.main.notice("EIP: {0:#010x}, EFLAGS: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_EIP), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_EFLAGS))
        self.main.notice("CS: {0:#06x}, SS: {1:#06x}", self.registers.segRead(CPU_SEGMENT_CS), \
          self.registers.segRead(CPU_SEGMENT_SS))
        self.main.notice("DS: {0:#06x}, ES: {1:#06x}", self.registers.segRead(CPU_SEGMENT_DS), \
          self.registers.segRead(CPU_SEGMENT_ES))
        self.main.notice("FS: {0:#06x}, GS: {1:#06x}", self.registers.segRead(CPU_SEGMENT_FS), \
          self.registers.segRead(CPU_SEGMENT_GS))
        self.main.notice("CR0: {0:#010x}, CR2: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_CR0), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_CR2))
        self.main.notice("CR3: {0:#010x}, CR4: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_CR3), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_CR4))
        self.main.notice("DR0: {0:#010x}, DR1: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_DR0), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_DR1))
        self.main.notice("DR2: {0:#010x}, DR3: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_DR2), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_DR3))
        self.main.notice("DR6: {0:#010x}, DR7: {1:#010x}\n\n", self.registers.regReadUnsignedDword(CPU_REGISTER_DR6), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_DR7))
    cpdef doInfiniteCycles(self):
        cdef unsigned long int cycleInc
        try:
            while (not self.main.quitEmu):
                if (self.cpuHalted and self.main.exitIfCpuHalted):
                    self.main.quitFunc()
                    exit(1)
                    return
                elif ((self.cpuHalted and not self.main.exitIfCpuHalted) or (self.debugHalt and not self.debugSingleStep)):
                    if (self.asyncEvent):
                        self.handleAsyncEvent()
                        continue
                    sleep(0.2)
                    continue
                cycleInc = self.cycles >> 14
                if (cycleInc > self.oldCycleInc):
                    self.oldCycleInc = cycleInc
                    sleep(0.000001) # FIXME: HACK: TODO: timing issue.
                self.doCycle()
        except:
            print_exc()
            self.main.exitError('doInfiniteCycles: exception, exiting...')
    cpdef doCycle(self):
        if (self.cpuHalted or self.main.quitEmu or (self.debugHalt and not self.debugSingleStep)):
            return
        if (self.debugHalt and self.debugSingleStep):
            self.debugSingleStep = False
        self.cycles += CPU_CLOCK_TICK
        self.registers.resetPrefixes()
        #self.saveCurrentInstPointer()
        if (self.asyncEvent):
            self.handleAsyncEvent()
        self.opcode = self.registers.getCurrentOpcodeAddWithAddr(&self.savedCs, &self.savedEip)
        if (self.opcode in OPCODE_PREFIXES):
            self.opcode = self.parsePrefixes(self.opcode)
        self.registers.readCodeSegSize()
        #self.main.debug("Current Opcode: {0:#04x}; It's EIP: {1:#06x}, CS: {2:#06x}", self.opcode, self.savedEip, self.savedCs)
        if (self.main.debugEnabled):
            self.main.debug("Current Opcode: {0:#04x}; It's EIP: {1:#06x}, CS: {2:#06x}", self.opcode, self.savedEip, self.savedCs)
            #self.cpuDump()
        #if (self.savedEip == 0x and self.savedCs == 0x):
        #    self.cpuDump()
        try:
            if (not self.opcodes.executeOpcode(self.opcode)):
                self.main.notice("Opcode not found. (opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x})", self.opcode, self.savedEip, self.savedCs)
                raise ChemuException(CPU_EXCEPTION_UD)
        except ChemuException as exception: # exception
            self.exceptionLevel += 1
            if (self.exceptionLevel == 1):
                self.handleException(exception) # execute exception handler
            elif (self.exceptionLevel == 2):
                self.exception(CPU_EXCEPTION_DF, 0) # exec DF double fault
            elif (self.exceptionLevel == 3):
                if (self.main.exitOnTripleFault):
                    self.main.exitError("CPU::doCycle: TRIPLE FAULT! exit.")
                else:
                    self.main.notice("CPU::doCycle: TRIPLE FAULT! reset.")
                    self.cpu.reset()
        except:
            print_exc()
            self.main.exitError('doCycle: exception while handling opcode, exiting... (opcode: {0:#04x})', self.opcode)
    cpdef run(self):
        self.registers = Registers(self.main)
        self.opcodes = Opcodes(self.main)
        self.opcodes.registers = self.registers
        self.registers.run()
        self.opcodes.run()
        self.reset()
        self.doInfiniteCycles()
    ###

