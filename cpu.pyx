
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"
include "cpu_globals.pxi"

from sys import exit #, stdout, stderr
from time import sleep
from traceback import print_exc
from misc import HirnwichseException


cdef class Cpu:
    def __init__(self, Hirnwichse main):
        self.main = main
    cdef inline void reset(self):
        self.savedCs  = 0xf000
        self.savedEip = 0xfff0
        self.cpuHalted = self.debugHalt = self.debugSingleStep = self.INTR = self.HRQ = False
        self.debugHalt = self.main.debugHalt
        self.savedSs = self.savedEsp = self.cycles = 0
        self.registers.reset()
    cdef inline void saveCurrentInstPointer(self) nogil:
        self.savedCs  = self.registers.segRead(CPU_SEGMENT_CS)
        self.savedEip = self.registers.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.savedSs  = self.registers.segRead(CPU_SEGMENT_SS)
        self.savedEsp = self.registers.regReadUnsignedDword(CPU_REGISTER_ESP)
    cdef void handleAsyncEvent(self):
        cdef unsigned char irqVector, oldIF
        # This is only for IRQs! (exceptions will use cpu.exception)
        oldIF = self.registers.if_flag
        if (self.INTR and oldIF):
            irqVector = (<Pic>self.main.platform.pic).IAC()
            self.opcodes.interrupt(irqVector)
        elif (self.HRQ):
            (<IsaDma>self.main.platform.isadma).raiseHLDA()
        if (not ((self.INTR and oldIF) or self.HRQ)):
            self.asyncEvent = False
            self.cpuHalted = False
        return
    cdef int exception(self, unsigned char exceptionId, signed int errorCode=-1) except BITMASK_BYTE_CONST:
        #self.main.debugEnabled = True
        if (exceptionId in CPU_EXCEPTIONS_FAULT_GROUP):
            self.registers.segWriteSegment((<Segment>self.registers.segments.cs), self.savedCs)
            self.registers.regWriteDword(CPU_REGISTER_EIP, self.savedEip)
        self.registers.segWriteSegment((<Segment>self.registers.segments.ss), self.savedSs)
        self.registers.regWriteDword(CPU_REGISTER_ESP, self.savedEsp)
        #elif (exceptionId in CPU_EXCEPTIONS_TRAP_GROUP):
        #    self.savedEip = <unsigned int>(self.savedEip+1)
        if (exceptionId == CPU_EXCEPTION_UD):
            self.main.notice("CPU::exception: UD: Opcode not found. (opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x})", self.opcode, self.savedEip, self.savedCs)
        else:
            self.main.notice("CPU::exception: Handle exception {0:d}. (opcode: {1:#04x}; EIP: {2:#06x}, CS: {3:#06x})", exceptionId, self.opcode, self.savedEip, self.savedCs)
        self.main.notice("Running exception_1.0: exceptionId: {0:#04x}, errorCode: {1:#04x}", exceptionId, errorCode)
        self.cpuDump()
        if (exceptionId in CPU_EXCEPTIONS_FAULT_GROUP and exceptionId != CPU_EXCEPTION_DB):
            self.registers.rf = True
        elif (exceptionId in CPU_EXCEPTIONS_TRAP_GROUP and self.registers.repPrefix):
            self.registers.rf = True
        self.main.notice("Running exception_1.1: exceptionId: {0:#04x}, errorCode: {1:#04x}", exceptionId, errorCode)
        self.cpuDump()
        if (exceptionId in CPU_EXCEPTIONS_WITH_ERRORCODE):
            if (errorCode == -1):
                self.main.exitError("CPU exception: errorCode should be set, is -1.")
                return True
            self.opcodes.interrupt(exceptionId, errorCode)
        else:
            self.opcodes.interrupt(exceptionId)
        self.main.notice("Running exception_2: exceptionId: {0:#04x}, errorCode: {1:#04x}", exceptionId, errorCode)
        self.cpuDump()
        #if (exceptionId == CPU_EXCEPTION_GP and self.opcode == 0x8a and self.savedEip == 0x310a and self.savedCs == 0x17ff):
        #    self.main.debugEnabledTest = self.main.debugEnabled = True
        #if (exceptionId == CPU_EXCEPTION_GP and self.opcode == 0xae):
        #    self.main.notice("Running exception_3: sleep()")
        #    stdout.flush()
        #    stderr.flush()
        #    #sleep(3600)
        #    exit()
        return True
    cdef int handleException(self, object exception) except BITMASK_BYTE_CONST:
        cdef unsigned char exceptionId
        cdef signed int errorCode
        #if (self.savedCs == 0x70 and self.savedEip == 0x3b2):
        #if (self.savedCs == 0x70 and self.savedEip == 0x382):
        #    self.main.debugEnabled = True
        #if (self.savedCs == 0xfcbf and self.savedEip == 0x2f27 and self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx == 0xc10f30bc):
        #if (self.savedCs == 0xfcb2 and self.savedEip == 0x2ff7 and self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx == 0xc10f30bc):
        #if (self.savedCs == 0x70 and self.savedEip == 0x0382):
        #if (self.savedCs == 0xc000 and self.savedEip == 0x152):
        #    self.main.debugEnabled = self.main.debugEnabledTest = True
        if (len(exception.args) not in (1, 2)):
            self.main.exitError('ERROR: exception argument length not in (1, 2); is {0:d}', len(exception.args))
            return True
        errorCode = -1
        if (len(exception.args) == 2):
            if (not isinstance(exception.args[1], int)):
                self.main.exitError('ERROR: errorCode not a int; type is {0:s}', type(exception.args[1]))
                return True
            errorCode = exception.args[1]
        if (not isinstance(exception.args[0], int)):
            self.main.exitError('ERROR: exceptionId not a int; type is {0:s}', type(exception.args[0]))
            return True
        exceptionId = exception.args[0]
        self.exception(exceptionId, errorCode)
        return True
    cdef unsigned char parsePrefixes(self, unsigned char opcode) nogil except? BITMASK_BYTE_CONST:
        cdef unsigned char count
        count = 0
        while (opcode in OPCODE_PREFIXES and not self.main.quitEmu):
            count += 1
            if (count >= 16):
                with gil:
                    raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (opcode == OPCODE_PREFIX_OP):
                self.registers.operandSizePrefix = True
            elif (opcode == OPCODE_PREFIX_ADDR):
                self.registers.addressSizePrefix = True
            elif (opcode in OPCODE_PREFIX_REPS):
                self.registers.repPrefix = opcode
            else:
                if (opcode == OPCODE_PREFIX_CS):
                    self.registers.segmentOverridePrefix = (<PyObject*>self.registers.segments.cs)
                elif (opcode == OPCODE_PREFIX_SS):
                    self.registers.segmentOverridePrefix = (<PyObject*>self.registers.segments.ss)
                elif (opcode == OPCODE_PREFIX_DS):
                    self.registers.segmentOverridePrefix = (<PyObject*>self.registers.segments.ds)
                elif (opcode == OPCODE_PREFIX_ES):
                    self.registers.segmentOverridePrefix = (<PyObject*>self.registers.segments.es)
                elif (opcode == OPCODE_PREFIX_FS):
                    self.registers.segmentOverridePrefix = (<PyObject*>self.registers.segments.fs)
                elif (opcode == OPCODE_PREFIX_GS):
                    self.registers.segmentOverridePrefix = (<PyObject*>self.registers.segments.gs)
            ### TODO: I don't think, that we ever need lockPrefix.
            #elif (opcode == OPCODE_PREFIX_LOCK):
            #    self.main.notice("CPU::parsePrefixes: LOCK-prefix is selected! (unimplemented, bad things may happen.)")
            opcode = self.registers.getCurrentOpcodeAddUnsignedByte()
        return opcode
    cdef void cpuDump(self):
        self.main.notice("EAX: {0:#010x}, ECX: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_EAX), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_ECX))
        self.main.notice("EDX: {0:#010x}, EBX: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_EDX), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_EBX))
        self.main.notice("ESP: {0:#010x}, EBP: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_ESP), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_EBP))
        self.main.notice("ESI: {0:#010x}, EDI: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_ESI), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_EDI))
        self.main.notice("EIP: {0:#010x}, EFLAGS: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_EIP), \
          self.registers.readFlags())
        self.main.notice("CS: {0:#06x}, SS: {1:#06x}", self.registers.segRead(CPU_SEGMENT_CS), \
          self.registers.segRead(CPU_SEGMENT_SS))
        self.main.notice("DS: {0:#06x}, ES: {1:#06x}", self.registers.segRead(CPU_SEGMENT_DS), \
          self.registers.segRead(CPU_SEGMENT_ES))
        self.main.notice("FS: {0:#06x}, GS: {1:#06x}", self.registers.segRead(CPU_SEGMENT_FS), \
          self.registers.segRead(CPU_SEGMENT_GS))
        self.main.notice("LDTR: {0:#06x}, LTR: {1:#06x}", (<Segments>self.registers.segments).ldtr, \
          (<Segment>self.registers.segments.tss).segmentIndex)
        self.main.notice("CR0: {0:#010x}, CR2: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_CR0), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_CR2))
        self.main.notice("CR3: {0:#010x}, CR4: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_CR3), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_CR4))
        self.main.notice("DR0: {0:#010x}, DR1: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_DR0), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_DR1))
        self.main.notice("DR2: {0:#010x}, DR3: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_DR2), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_DR3))
        self.main.notice("DR6: {0:#010x}, DR7: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_DR6), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_DR7))
        self.main.notice("savedCS: {0:#06x}, savedSS: {1:#06x}", self.savedCs, \
          self.savedSs)
        self.main.notice("savedEIP: {0:#010x}, savedESP: {1:#010x}", self.savedEip, self.savedEsp)
        #self.main.notice("CS.limit: {0:#06x}, SS.limit: {1:#06x}", (<Segment>self.registers.segments.cs).limit, \
        #  (<Segment>self.registers.segments.ss).limit)
        #self.main.notice("DS.limit: {0:#06x}, ES.limit: {1:#06x}", (<Segment>self.registers.segments.ds).limit, \
        #  (<Segment>self.registers.segments.es).limit)
        #self.main.notice("FS.limit: {0:#06x}, GS.limit: {1:#06x}", (<Segment>self.registers.segments.fs).limit, \
        #  (<Segment>self.registers.segments.gs).limit)
        self.main.notice("Opcode: {0:#04x}\n\n", self.opcode)
    cdef void doInfiniteCycles(self):
        try:
            while (not self.main.quitEmu):
                if (self.cpuHalted and self.main.exitIfCpuHalted):
                    self.main.quitFunc()
                    exit(1)
                    return
                elif ((self.debugHalt and not self.debugSingleStep) or (self.cpuHalted and not self.main.exitIfCpuHalted)):
                    if (self.asyncEvent and not self.registers.ssInhibit):
                        self.registers.resetPrefixes()
                        self.saveCurrentInstPointer()
                        self.registers.readCodeSegSize()
                        self.handleAsyncEvent()
                    else:
                        self.registers.ssInhibit = False
                        if (self.main.platform.vga and self.main.platform.vga.ui):
                            self.main.platform.vga.ui.handleEventsWithoutWaiting()
                        sleep(0.2)
                    continue
                self.doCycle()
        except:
            print_exc()
            self.main.exitError('doInfiniteCycles: exception, exiting...')
    cdef void doCycle(self):
        if (self.debugHalt and self.debugSingleStep):
            self.debugSingleStep = False
        #self.registers.reloadCpuCache()
        self.cycles += CPU_CLOCK_TICK
        self.registers.resetPrefixes()
        self.saveCurrentInstPointer()
        if (not (<unsigned short>self.cycles) and not (<unsigned short>(self.cycles>>4))):
            if (self.main.platform.vga and self.main.platform.vga.ui):
                self.main.platform.vga.ui.handleEventsWithoutWaiting()
        try:
            #if (self.registers.df):
            #    self.main.notice("CPU::doCycle: DF-flag isn't fully supported yet!")
            if (self.registers.tf):
                self.main.notice("CPU::doCycle: TF-flag isn't fully supported yet!")
            if (not self.registers.ssInhibit):
                self.registers.readCodeSegSize()
                if (self.asyncEvent):
                    self.handleAsyncEvent()
                    return
                elif (self.registers.tf):
                    self.registers.ssInhibit = True
                # handle dr0-3 here
            else:
                self.registers.ssInhibit = False
                if (self.registers.tf):
                    self.registers.readCodeSegSize()
                    self.registers.tf = False
                    raise HirnwichseException(CPU_EXCEPTION_DB)
                    #return
            self.opcode = self.registers.getCurrentOpcodeAddUnsignedByte()
            if (self.opcode in OPCODE_PREFIXES):
                self.opcode = self.parsePrefixes(self.opcode)
            self.registers.readCodeSegSize()
            self.registers.rf = False
            #if (self.savedCs == 0x28 and self.savedEip == 0xc00013b7):
            #if (self.savedCs == 0x28 and self.savedEip == 0xc00013d1):
            #    self.main.debugEnabledTest = True
            #if (self.savedCs == 0x28 and self.savedEip == 0xc03604fa):
            #if (self.savedCs == 0x9f and self.savedEip == 0xd0c4):
            #if (self.savedCs == 0x8 and self.savedEip == 0x80014068):
            #if (self.savedCs == 0x8 and self.savedEip == 0x803d2f73):
            #if (self.savedCs == 0x8 and self.savedEip == 0x803d3001):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x8 and self.savedEip == 0x80455574 and self.registers.regReadUnsignedDword(CPU_REGISTER_EBP) == 0x0004f534):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x8 and self.savedEip == 0x8042ac90 and self.registers.regReadUnsignedDword(CPU_REGISTER_EBP) == 0x0004f060):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x17ff and self.savedEip == 0x310a):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            if (self.main.debugEnabled or self.main.debugEnabledTest):
            #IF 1:
                self.main.notice("Current Opcode: {0:#04x}; It's EIP: {1:#06x}, CS: {2:#06x}", self.opcode, self.savedEip, self.savedCs)
                self.cpuDump()
                #self.main.notice("EAX: {0:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_EAX))
                #self.main.notice("ESP: {0:#010x}, EFLAGS: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_ESP), self.registers.readFlags())
            if (not self.opcodes.executeOpcode(self.opcode)):
                self.main.notice("Opcode not found. (opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x})", self.opcode, self.savedEip, self.savedCs)
                raise HirnwichseException(CPU_EXCEPTION_UD)
        except HirnwichseException as exception: # exception
            self.main.notice("Cpu::doCycle: testexc1")
            #stdout.flush()
            #print_exc()
            #stderr.flush()
            try:
                self.handleException(exception) # execute exception handler
            except HirnwichseException as exception: # exception
                self.main.notice("Cpu::doCycle: testexc2")
                self.main.notice("Cpu::doCycle: testexc2.1; repr=={0:s}", repr(exception.args))
                try:
                    self.exception(CPU_EXCEPTION_DF, 0) # exec DF double fault
                except HirnwichseException as exception: # exception
                    self.main.notice("Cpu::doCycle: testexc3")
                    if (self.main.exitOnTripleFault):
                        self.main.exitError("CPU::doCycle: TRIPLE FAULT! exit.")
                    else:
                        self.main.notice("CPU::doCycle: TRIPLE FAULT! reset.")
                        self.cpu.reset()
                except:
                    print_exc()
                    self.main.exitError('doCycle: exception1 while handling opcode, exiting... (opcode: {0:#04x})', self.opcode)
            except:
                print_exc()
                self.main.exitError('doCycle: exception2 while handling opcode, exiting... (opcode: {0:#04x})', self.opcode)
        except:
            print_exc()
            self.main.exitError('doCycle: exception3 while handling opcode, exiting... (opcode: {0:#04x})', self.opcode)
    cdef run(self, unsigned char infiniteCycles = True):
        self.registers = Registers(self.main)
        self.opcodes = Opcodes(self.main, self)
        self.opcodes.registers = self.registers
        self.registers.run()
        self.opcodes.run()
        self.reset()
        if (infiniteCycles):
            self.doInfiniteCycles()
    ###

