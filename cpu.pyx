
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"
include "cpu_globals.pxi"

from sys import exit #, stdout, stderr
from time import sleep, time
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
        self.savedSs = self.savedEsp = self.cycles = self.lasttime = 0
        self.operSize = self.addrSize = 0
        self.resetPrefixes()
        self.registers.reset()
    cdef inline void saveCurrentInstPointer(self) nogil:
        self.savedCs  = self.registers.segRead(CPU_SEGMENT_CS)
        self.savedEip = self.registers.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.savedSs  = self.registers.segRead(CPU_SEGMENT_SS)
        self.savedEsp = self.registers.regReadUnsignedDword(CPU_REGISTER_ESP)
    cdef void handleAsyncEvent(self):
        cdef uint8_t irqVector, oldIF
        # This is only for IRQs! (exceptions will use cpu.exception)
        oldIF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.if_flag
        if (self.INTR and oldIF):
            irqVector = (<Pic>self.main.platform.pic).IAC()
            self.opcodes.interrupt(irqVector)
        elif (self.HRQ):
            (<IsaDma>self.main.platform.isadma).raiseHLDA()
        if (not ((self.INTR and oldIF) or self.HRQ)):
            self.asyncEvent = False
            self.cpuHalted = False
        return
    cdef int exception(self, uint8_t exceptionId, int32_t errorCode=-1) except BITMASK_BYTE_CONST:
        #self.main.debugEnabled = True
        if (exceptionId in CPU_EXCEPTIONS_FAULT_GROUP):
            self.registers.segWriteSegment(&self.registers.segments.cs, self.savedCs)
            self.registers.regWriteDword(CPU_REGISTER_EIP, self.savedEip)
        self.registers.segWriteSegment(&self.registers.segments.ss, self.savedSs)
        self.registers.regWriteDword(CPU_REGISTER_ESP, self.savedEsp)
        #elif (exceptionId in CPU_EXCEPTIONS_TRAP_GROUP):
        #    self.savedEip = <uint32_t>(self.savedEip+1)
        IF COMP_DEBUG:
            if (exceptionId == CPU_EXCEPTION_UD):
                self.main.notice("CPU::exception: UD: Opcode not found. (opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x})", self.opcode, self.savedEip, self.savedCs)
            else:
                self.main.notice("CPU::exception: Handle exception {0:d}. (opcode: {1:#04x}; EIP: {2:#06x}, CS: {3:#06x})", exceptionId, self.opcode, self.savedEip, self.savedCs)
        IF COMP_DEBUG:
            self.main.notice("Running exception_1.0: exceptionId: {0:#04x}, errorCode: {1:#04x}", exceptionId, errorCode)
            self.cpuDump()
        if (exceptionId in CPU_EXCEPTIONS_FAULT_GROUP and exceptionId != CPU_EXCEPTION_DB):
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.rf = True
        elif (exceptionId in CPU_EXCEPTIONS_TRAP_GROUP and self.repPrefix):
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.rf = True
        IF COMP_DEBUG:
            self.main.notice("Running exception_1.1: exceptionId: {0:#04x}, errorCode: {1:#04x}", exceptionId, errorCode)
            self.cpuDump()
        if (exceptionId in CPU_EXCEPTIONS_WITH_ERRORCODE):
            if (errorCode == -1):
                self.main.exitError("CPU exception: errorCode should be set, is -1.")
                return True
            self.opcodes.interrupt(exceptionId, errorCode)
        else:
            self.opcodes.interrupt(exceptionId)
        IF COMP_DEBUG:
            self.main.notice("Running exception_2: exceptionId: {0:#04x}, errorCode: {1:#04x}", exceptionId, errorCode)
            self.cpuDump()
        #if (exceptionId == CPU_EXCEPTION_GP and self.opcode == 0xcf and self.savedEip == 0x80139a2c and self.savedCs == 0x0008):
        #    self.main.debugEnabledTest = self.main.debugEnabled = True
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
        cdef uint8_t exceptionId
        cdef int32_t errorCode
        #if (self.savedCs == 0x70 and self.savedEip == 0x3b2):
        #if (self.savedCs == 0x70 and self.savedEip == 0x382):
        #    self.main.debugEnabled = True
        #if (self.savedCs == 0xfcbf and self.savedEip == 0x2f27 and self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx == 0xc10f30bc):
        #if (self.savedCs == 0xfcb2 and self.savedEip == 0x2ff7 and self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx == 0xc10f30bc):
        #if (self.savedCs == 0x70 and self.savedEip == 0x0382):
        #if (self.savedCs == 0xc000 and self.savedEip == 0x152):
        #    self.main.debugEnabledTest = self.main.debugEnabled = True
        #if (self.savedCs == 0x8 and self.savedEip == 0x808b5d6b):
        #    self.main.debugEnabledTest = self.main.debugEnabled = True
        #if (self.savedCs == 0x137 and self.savedEip == 0x7fcf1025):
        #    self.main.debugEnabledTest = self.main.debugEnabled = True
        #if (self.savedCs == 0x17cf and self.savedEip == 0x56ad):
        #    self.main.debugEnabledTest = self.main.debugEnabled = True
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
    cdef uint8_t parsePrefixes(self, uint8_t opcode) nogil except? BITMASK_BYTE_CONST:
        cdef uint8_t count
        count = 0
        while (opcode in OPCODE_PREFIXES and not self.main.quitEmu):
            count += 1
            if (count >= 16):
                with gil:
                    raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (opcode == OPCODE_PREFIX_OP):
                self.operandSizePrefix = True
            elif (opcode == OPCODE_PREFIX_ADDR):
                self.addressSizePrefix = True
            elif (opcode in OPCODE_PREFIX_REPS):
                self.repPrefix = opcode
            elif (opcode == OPCODE_PREFIX_CS):
                self.segmentOverridePrefix = &self.registers.segments.cs
            elif (opcode == OPCODE_PREFIX_SS):
                self.segmentOverridePrefix = &self.registers.segments.ss
            elif (opcode == OPCODE_PREFIX_DS):
                self.segmentOverridePrefix = &self.registers.segments.ds
            elif (opcode == OPCODE_PREFIX_ES):
                self.segmentOverridePrefix = &self.registers.segments.es
            elif (opcode == OPCODE_PREFIX_FS):
                self.segmentOverridePrefix = &self.registers.segments.fs
            elif (opcode == OPCODE_PREFIX_GS):
                self.segmentOverridePrefix = &self.registers.segments.gs
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
          self.registers.regReadUnsignedDword(CPU_REGISTER_EFLAGS))
        self.main.notice("CS: {0:#06x}, SS: {1:#06x}", self.registers.segRead(CPU_SEGMENT_CS), \
          self.registers.segRead(CPU_SEGMENT_SS))
        self.main.notice("DS: {0:#06x}, ES: {1:#06x}", self.registers.segRead(CPU_SEGMENT_DS), \
          self.registers.segRead(CPU_SEGMENT_ES))
        self.main.notice("FS: {0:#06x}, GS: {1:#06x}", self.registers.segRead(CPU_SEGMENT_FS), \
          self.registers.segRead(CPU_SEGMENT_GS))
        self.main.notice("LDTR: {0:#06x}, LTR: {1:#06x}", self.registers.ldtr, \
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
        #self.main.notice("CS.limit: {0:#06x}, SS.limit: {1:#06x}", (<Segment>self.registers.segments.cs).gdtEntry.limit, \
        #  (<Segment>self.registers.segments.ss).gdtEntry.limit)
        #self.main.notice("DS.limit: {0:#06x}, ES.limit: {1:#06x}", (<Segment>self.registers.segments.ds).gdtEntry.limit, \
        #  (<Segment>self.registers.segments.es).gdtEntry.limit)
        #self.main.notice("FS.limit: {0:#06x}, GS.limit: {1:#06x}", (<Segment>self.registers.segments.fs).gdtEntry.limit, \
        #  (<Segment>self.registers.segments.gs).gdtEntry.limit)
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
                        self.resetPrefixes()
                        self.saveCurrentInstPointer()
                        self.readCodeSegSize()
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
        cdef uint64_t temptime
        if (self.debugHalt and self.debugSingleStep):
            self.debugSingleStep = False
        #self.registers.reloadCpuCache()
        self.cycles += CPU_CLOCK_TICK
        self.resetPrefixes()
        self.saveCurrentInstPointer()
        #if (not (<uint16_t>self.cycles) and not (<uint16_t>(self.cycles>>4))):
        if (not (<uint16_t>self.cycles) and not (<uint16_t>(self.cycles>>6))):
        #if (not (<uint16_t>self.cycles) and not (<uint16_t>(self.cycles>>8))):
        #if (not (<uint16_t>self.cycles) and not (<uint16_t>(self.cycles>>16))):
            #temptime = ttime(NULL)*100
            #if (temptime - self.lasttime >= 20):
            temptime = ttime(NULL)
            if (temptime - self.lasttime >= 1):
                if (self.main.platform.vga and self.main.platform.vga.ui):
                    self.main.platform.vga.ui.handleEventsWithoutWaiting()
                self.lasttime = temptime
        try:
            #if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
            #    self.main.notice("CPU::doCycle: DF-flag isn't fully supported yet!")
            if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.tf):
                self.main.notice("CPU::doCycle: TF-flag isn't fully supported yet! Opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x}", self.opcode, self.savedEip, self.savedCs)
                self.cpuDump()
            if (not self.registers.ssInhibit):
                self.readCodeSegSize()
                if (self.asyncEvent):
                    self.handleAsyncEvent()
                    return
                elif (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.tf):
                    self.registers.ssInhibit = True
                # handle dr0-3 here
            else:
                self.registers.ssInhibit = False
                if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.tf):
                    self.readCodeSegSize()
                    self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.tf = False
                    raise HirnwichseException(CPU_EXCEPTION_DB)
                    #return
            self.opcode = self.registers.getCurrentOpcodeAddUnsignedByte()
            if (self.opcode in OPCODE_PREFIXES):
                self.opcode = self.parsePrefixes(self.opcode)
            self.readCodeSegSize()
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.rf = False
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
            #if (self.savedCs == 0x8 and self.savedEip == 0x8080275a):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x8 and self.savedEip == 0x808c8e52):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x8 and self.savedEip == 0x8098147e and self.registers.regReadUnsignedDword(CPU_REGISTER_EDI) == 0xb9400000):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x137 and self.savedEip == 0x7fcf2ce9):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x28 and self.savedEip == 0xc002ec58):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x28 and self.savedEip == 0xc0001e7a):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x2b and self.savedEip == 0x1c000193 and self.opcode == 0x57):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x8 and self.savedEip == 0x00320ba7):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x0 and self.savedEip == 0x7c00):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x2b and self.main.debugEnabledTest):
            #    self.main.debugEnabled = True
            #if (self.savedCs == 0x2000 and self.savedEip == 0x1c8):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #else:
            #    self.main.debugEnabled = False
            #if (self.savedCs == 0xffff and self.savedEip == 0xb09):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x835 and self.savedEip == 0x20a5):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x28 and self.savedEip == 0xc03603af):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x28 and self.savedEip == 0xc0372ffd):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            #if (self.savedCs == 0x28 and self.savedEip == 0xc002a555):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            if (self.main.debugEnabled):
            #if (self.main.debugEnabled or self.main.debugEnabledTest):
            #if ((self.main.debugEnabled or self.main.debugEnabledTest) and self.savedCs != 0x50):
            #if (self.savedCs == 0x2b):
            #if (self.savedCs == 0x8 and self.savedEip == 0x312296):
            #IF 1:
                self.main.notice("Current Opcode: {0:#04x}; It's EIP: {1:#06x}, CS: {2:#06x}", self.opcode, self.savedEip, self.savedCs)
                self.cpuDump()
                #if (self.savedEip == 0x1c000178):
                #    self.main.notice("ds:[ds:[edx]-1]=={0:#010x}", self.registers.mmReadValueUnsignedDword(self.registers.mmReadValueUnsignedDword(self.registers.regReadUnsignedDword(CPU_REGISTER_EDX), (<Segment>self.registers.segments.ds), False)-1, (<Segment>self.registers.segments.ds), False))
                #if (self.savedEip == 0xd02006d1):
                #    self.main.notice("ds:[esi-1]=={0:#010x}", self.registers.mmReadValueUnsignedDword(self.registers.regReadUnsignedDword(CPU_REGISTER_ESI)-1, (<Segment>self.registers.segments.ds), False))
                #self.main.notice("EAX: {0:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_EAX))
                #self.main.notice("ESP: {0:#010x}, EFLAGS: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_ESP), self.registers.regReadUnsignedDword(CPU_REGISTER_EFLAGS))
            if (not self.opcodes.executeOpcode(self.opcode)):
                self.main.notice("Opcode not found. (opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x})", self.opcode, self.savedEip, self.savedCs)
                raise HirnwichseException(CPU_EXCEPTION_UD)
        except HirnwichseException as exception: # exception
            IF COMP_DEBUG:
                self.main.notice("Cpu::doCycle: testexc1")
            #stdout.flush()
            #print_exc()
            #stderr.flush()
            try:
                self.handleException(exception) # execute exception handler
            except HirnwichseException as exception: # exception
                IF COMP_DEBUG:
                    self.main.notice("Cpu::doCycle: testexc2")
                    self.main.notice("Cpu::doCycle: testexc2.1; repr=={0:s}", repr(exception.args))
                try:
                    self.exception(CPU_EXCEPTION_DF, 0) # exec DF double fault
                except HirnwichseException as exception: # exception
                    IF COMP_DEBUG:
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
    cdef run(self, uint8_t infiniteCycles = True):
        self.registers = Registers(self.main)
        self.opcodes = Opcodes(self.main, self)
        self.opcodes.registers = self.registers
        self.registers.run()
        self.opcodes.run()
        self.reset()
        if (infiniteCycles):
            self.doInfiniteCycles()
    ###

