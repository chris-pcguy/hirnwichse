
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"
include "cpu_globals.pxi"

from sys import exit
from time import sleep
from traceback import print_exc
from misc import HirnwichseException


cdef class Cpu:
    def __init__(self, Hirnwichse main):
        self.main = main
    cdef void reset(self):
        self.savedCs  = 0xf000
        self.savedEip = 0xfff0
        self.cpuHalted = self.debugHalt = self.debugSingleStep = self.INTR = \
          self.HRQ = False
        self.debugHalt = self.main.debugHalt
        self.cycles = self.oldCycleInc = 0
        self.registers.reset()
    cdef inline void saveCurrentInstPointer(self):
        self.savedCs  = self.registers.segRead(CPU_SEGMENT_CS)
        self.savedEip = self.registers.regReadUnsignedDword(CPU_REGISTER_EIP)
    cdef void setINTR(self, unsigned char state):
        self.INTR = state
        if (state):
            self.asyncEvent = True
            self.cpuHalted = False
    cdef void setHRQ(self, unsigned char state):
        self.HRQ = state
        if (state):
            self.asyncEvent = True
    cpdef handleAsyncEvent(self):
        cdef unsigned char irqVector, oldIF
        # This is only for IRQs! (exceptions will use cpu.exception)
        oldIF = self.registers.if_flag
        if (self.INTR and oldIF ):
            irqVector = (<Pic>self.main.platform.pic).IAC()
            self.opcodes.interrupt(irqVector)
        elif (self.HRQ):
            (<IsaDma>self.main.platform.isadma).raiseHLDA()
        if (not ((self.INTR and oldIF ) or self.HRQ) ):
            self.asyncEvent = False
        return
    cpdef exception(self, unsigned char exceptionId, signed int errorCode=-1):
        self.main.notice("Running exception: exceptionId: {0:#04x}, errorCode: {1:#04x}", exceptionId, errorCode)
        self.cpuDump()
        #self.main.debugEnabled = True
        if (exceptionId in CPU_EXCEPTIONS_FAULT_GROUP):
            self.registers.segWriteSegment((<Segment>self.registers.segments.cs), self.savedCs)
            self.registers.regWriteDword(CPU_REGISTER_EIP, self.savedEip)
        #elif (exceptionId in CPU_EXCEPTIONS_TRAP_GROUP):
        #    self.savedEip = <unsigned int>(self.savedEip+1)
        if (exceptionId in CPU_EXCEPTIONS_WITH_ERRORCODE):
            if (errorCode == -1):
                self.main.exitError("CPU exception: errorCode should be set, is -1.")
                return
            self.opcodes.interrupt(exceptionId, errorCode)
        else:
            self.opcodes.interrupt(exceptionId)
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
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (opcode == OPCODE_PREFIX_OP):
                self.registers.operandSizePrefix = True
            elif (opcode == OPCODE_PREFIX_ADDR):
                self.registers.addressSizePrefix = True
            elif (opcode == OPCODE_PREFIX_CS):
                self.registers.segmentOverridePrefix = (<Segment>self.registers.segments.cs)
            elif (opcode == OPCODE_PREFIX_SS):
                self.registers.segmentOverridePrefix = (<Segment>self.registers.segments.ss)
            elif (opcode == OPCODE_PREFIX_DS):
                self.registers.segmentOverridePrefix = (<Segment>self.registers.segments.ds)
            elif (opcode == OPCODE_PREFIX_ES):
                self.registers.segmentOverridePrefix = (<Segment>self.registers.segments.es)
            elif (opcode == OPCODE_PREFIX_FS):
                self.registers.segmentOverridePrefix = (<Segment>self.registers.segments.fs)
            elif (opcode == OPCODE_PREFIX_GS):
                self.registers.segmentOverridePrefix = (<Segment>self.registers.segments.gs)
            elif (opcode in OPCODE_PREFIX_REPS):
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
          self.registers.readFlags())
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
        self.main.notice("DR6: {0:#010x}, DR7: {1:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_DR6), \
          self.registers.regReadUnsignedDword(CPU_REGISTER_DR7))
        self.main.notice("Opcode: {0:#04x}\n\n", self.opcode)
    cpdef doInfiniteCycles(self):
        try:
            while (not self.main.quitEmu):
                if (self.cpuHalted and self.main.exitIfCpuHalted):
                    self.main.quitFunc()
                    exit(1)
                    return
                elif ((self.debugHalt and not self.debugSingleStep) or (self.cpuHalted and not self.main.exitIfCpuHalted)):
                    if (self.asyncEvent and not self.registers.ssInhibit):
                        self.saveCurrentInstPointer()
                        self.handleAsyncEvent()
                    else:
                        if (self.main.platform.vga and self.main.platform.vga.ui):
                            self.main.platform.vga.ui.handleEventsWithoutWaiting()
                        sleep(0.2)
                    continue
                self.doCycle()
        except:
            print_exc()
            self.main.exitError('doInfiniteCycles: exception, exiting...')
    cpdef doCycle(self):
        if (self.debugHalt and self.debugSingleStep):
            self.debugSingleStep = False
        #self.registers.reloadCpuCache()
        self.cycles += CPU_CLOCK_TICK
        self.registers.resetPrefixes()
        #self.saveCurrentInstPointer()
        if (<unsigned short>self.cycles == 0x00):
            if (self.main.platform.vga and self.main.platform.vga.ui):
                self.main.platform.vga.ui.handleEventsWithoutWaiting()
        if (self.registers.df):
            self.main.notice("CPU::doCycle: DF-flag isn't fully supported yet!")
        if (self.registers.tf):
            self.main.notice("CPU::doCycle: TF-flag isn't fully supported yet!")
        if (not self.registers.ssInhibit):
            self.registers.readCodeSegSize()
            self.saveCurrentInstPointer()
            if (self.asyncEvent):
                self.handleAsyncEvent()
                return
            elif (self.registers.tf):
                self.registers.tf = False
                self.exception(CPU_EXCEPTION_DB, -1)
                return
        else:
            self.registers.ssInhibit = False
        self.opcode = self.registers.getCurrentOpcodeAddWithAddr(&self.savedCs, &self.savedEip)
        if (self.opcode in OPCODE_PREFIXES):
            self.opcode = self.parsePrefixes(self.opcode)
        self.registers.readCodeSegSize()
        ##if (self.savedEip == 0xf0101040):
        #if (self.savedEip == 0x2001):
        ##if (self.savedEip == 0x169c):
        ##if (self.savedEip == 0x1041):
        #if (self.savedEip == 0xc000154f):
        #if (self.savedCs == 0x28):
        #    self.main.debugEnabled = True
        #elif (self.savedCs == 0x835):
        #    self.main.debugEnabled = True
        #elif (self.savedCs == 0x2ec6):
        #    self.main.debugEnabled = True
        #else:
        #    self.main.debugEnabled = False
        #if (self.savedCs == 0x835):
        #    self.main.debugEnabled = True
        #elif (self.savedCs == 0x2ec6):
        #    self.main.debugEnabled = True
        #elif (self.savedCs == 0x28):
        #    self.main.debugEnabled = False
        #else:
        #    self.main.debugEnabled = False
        if (self.main.debugEnabled):
            self.main.notice("Current Opcode: {0:#04x}; It's EIP: {1:#06x}, CS: {2:#06x}", self.opcode, self.savedEip, self.savedCs)
            #self.main.notice("Cpu::doCycle: Gdt::tableLimit=={0:#06x}", self.registers.segments.gdt.tableLimit)
            # LIN 0xffbfec08 ; PHY 0x00305c08
            #self.main.notice("Cpu::doCycle: test3=={0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x309c10))
            #self.main.notice("Cpu::doCycle: test4=={0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00248dc3))
            #self.main.notice("Cpu::doCycle: test5=={0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x002450d0))
            #self.main.notice("Cpu::doCycle: test6=={0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00248de8))
            # LIN 0xc036c008; PHY 0x00249008
            #self.main.notice("Cpu::doCycle: test7=={0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00249008))
            #self.main.notice("Cpu::doCycle: test2=={0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x307030))
            #self.main.notice("Cpu::doCycle: test1=={0:#010x}==0x0033d227", self.main.mm.mmPhyReadValueUnsignedDword(0x305c08))
            #try:
            #    self.main.notice("Cpu::doCycle: test8=={0:#010x}", self.registers.mmReadValueUnsignedDword(0xc13c7f9c, (<Segment>self.registers.segments.ss), False))
            #except HirnwichseException:
            #    self.main.notice("Cpu::doCycle: test8 exception")
            self.cpuDump()
        try:
            if (not self.opcodes.executeOpcode(self.opcode)):
                self.main.notice("Opcode not found. (opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x})", self.opcode, self.savedEip, self.savedCs)
                raise HirnwichseException(CPU_EXCEPTION_UD)
        except HirnwichseException as exception: # exception
            self.main.notice("Cpu::doCycle: testexc1")
            try:
                self.handleException(exception) # execute exception handler
            except HirnwichseException as exception: # exception
                try:
                    self.exception(CPU_EXCEPTION_DF, 0) # exec DF double fault
                except HirnwichseException as exception: # exception
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
    cpdef run(self, unsigned char infiniteCycles = True):
        self.registers = Registers(self.main)
        self.opcodes = Opcodes(self.main)
        self.opcodes.registers = self.registers
        self.registers.run()
        self.opcodes.run()
        self.reset()
        if (infiniteCycles):
            self.doInfiniteCycles()
    ###

