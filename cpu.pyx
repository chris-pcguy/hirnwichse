
from time import sleep
from sys import exc_info
from misc import ChemuException


include "globals.pxi"


cdef class Cpu:
    def __init__(self, object main):
        self.main = main
    cdef reset(self):
        self.savedCs  = 0xf000
        self.savedEip = 0xfff0
        self.cpuHalted = False
        self.debugHalt = False
        self.debugSingleStep = False
        self.INTR = False
        self.HRQ = False
        self.cycles = 0
        self.registers.reset()
    cdef saveCurrentInstPointer(self):
        self.savedCs  = self.registers.segRead(CPU_SEGMENT_CS)
        self.savedEip = self.registers.regRead(CPU_REGISTER_EIP, False)
    cdef setINTR(self, unsigned char state):
        self.INTR = state
        self.asyncEvent = True
    cdef setHRQ(self, unsigned char state):
        self.HRQ = state
        if (state):
            self.asyncEvent = True
    cdef handleAsyncEvent(self):
        cdef unsigned char irqVector, oldIF
        # This is only for IRQs! (exceptions will use cpu.exception)
        oldIF = self.registers.getEFLAG(FLAG_IF)!=0
        if (self.INTR and oldIF ):
            irqVector = (<Pic>self.main.platform.pic).IAC()
            self.opcodes.interrupt(irqVector, -1)
            self.saveCurrentInstPointer()
        elif (self.HRQ):
            (<IsaDma>self.main.platform.isadma).raiseHLDA()
        if (not ((self.INTR and oldIF ) or self.HRQ) ):
            self.asyncEvent = False
        return
    cdef exception(self, unsigned char exceptionId, long errorCode):
        self.main.printMsg("Running exception: exceptionId: {0:#04x}, errorCode: {1:#04x}", exceptionId, errorCode)
        ##if (exceptionId in CPU_EXCEPTIONS_FAULT_GROUP):
        if (exceptionId in CPU_EXCEPTIONS_TRAP_GROUP):
            self.savedEip += 1
            self.savedEip &= 0xffffffff
        self.registers.segWrite(CPU_SEGMENT_CS, self.savedCs)
        self.registers.regWrite(CPU_REGISTER_EIP, self.savedEip)
        if (exceptionId in CPU_EXCEPTIONS_WITH_ERRORCODE):
            if (errorCode == -1):
                self.main.exitError("CPU exception: errorCode should be set, is -1.")
                return
            self.opcodes.interrupt(exceptionId, errorCode)
            return
        self.opcodes.interrupt(exceptionId, -1)
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
    cdef unsigned char parsePrefixes(self, unsigned char opcode):
        cdef unsigned char count
        cdef unsigned short segId
        count = 0
        # TODO: I don't think, that we ever need lockPrefix.
        while (opcode in OPCODE_PREFIXES):
            count += 1
            if (count >= 16):
                raise ChemuException(CPU_EXCEPTION_UD)
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
                    self.main.exitError("parsePrefixes: {0:#04x} is not a segment prefix.", opcode)
                    return 0
                self.registers.segmentOverridePrefix = segId
            elif (opcode == OPCODE_PREFIX_OP):
                self.registers.operandSizePrefix = True
            elif (opcode == OPCODE_PREFIX_ADDR):
                self.registers.addressSizePrefix = True

            opcode = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)

        return opcode
    cpdef doInfiniteCycles(self):
        try:
            while (not self.main.quitEmu):
                if ((self.cpuHalted and self.main.exitIfCpuHalted) or self.main.quitEmu):
                    self.main.quitEmu = True
                    return
                elif ((self.cpuHalted and not self.main.exitIfCpuHalted) or (self.debugHalt and not self.debugSingleStep)):
                    if (self.asyncEvent):
                        self.handleAsyncEvent()
                        continue
                    sleep(1)
                    continue
                if ((self.cycles % 5000) == 0):
                    self.main.pyroUI.pumpEvents()
                self.doCycle()
        except (SystemExit, KeyboardInterrupt):
            print(exc_info())
            self.main.quitEmu = True
            self.main.exitError('doInfiniteCycles: (SystemExit, KeyboardInterrupt) exception, exiting...', exitNow=True)
        except:
            print(exc_info())
            self.main.exitError('doInfiniteCycles: (else case) exception, exiting...', exitNow=True)
    cdef doCycle(self):
        if (self.cpuHalted or self.main.quitEmu or (self.debugHalt and not self.debugSingleStep)):
            return
        if (self.debugHalt and self.debugSingleStep):
            self.debugSingleStep = False
        self.cycles += 1
        self.registers.resetPrefixes()
        #self.saveCurrentInstPointer()
        if (self.asyncEvent):
            self.handleAsyncEvent()
        self.opcode = self.registers.getCurrentOpcodeAddWithAddr(&self.savedCs, &self.savedEip)
        if (self.opcode in OPCODE_PREFIXES):
            self.opcode = self.parsePrefixes(self.opcode)
        self.main.debug("Current Opcode: {0:#04x}; It's EIP: {1:#06x}, CS: {2:#06x}", self.opcode, self.savedEip, self.savedCs)
        try:
            if (not self.opcodes.executeOpcode(self.opcode)):
                self.main.printMsg("Opcode not found. (opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x})", self.opcode, self.savedEip, self.savedCs)
                raise ChemuException(CPU_EXCEPTION_UD)
        except ChemuException as exception: # exception
            try:
                self.handleException(exception) # execute exception handler
            except ChemuException as exception: # DF double fault
                try:
                    raise ChemuException(CPU_EXCEPTION_DF, 0) # exec DF double fault
                except ChemuException as exception:
                    try:
                        self.handleException(exception) # handle DF double fault
                    except ChemuException as exception: # DF double fault failed! triple fault... reset!
                        if (self.main.exitOnTripleFault):
                            self.main.exitError("CPU::doCycle: TRIPLE FAULT! exit.", exitNow=True)
                        else:
                            self.main.printMsg("CPU::doCycle: TRIPLE FAULT! reset.")
                            self.cpu.reset()
        except (SystemExit, KeyboardInterrupt):
            print(exc_info())
            self.main.quitEmu = True
            self.main.exitError('doCycle: (SystemExit, KeyboardInterrupt) exception while handling opcode, exiting... (opcode: {0:#04x})', self.opcode, exitNow=True)
        except:
            print(exc_info())
            self.main.exitError('doCycle: (else case) exception while handling opcode, exiting... (opcode: {0:#04x})', self.opcode, exitNow=True)
    cpdef run(self):
        self.registers = Registers(self.main)
        self.opcodes = Opcodes(self.main)
        self.registers.run()
        self.opcodes.run()
        self.reset()
        ##self.doInfiniteCycles()
        (<Misc>self.main.misc).createThread(self.doInfiniteCycles, True)
    ###

