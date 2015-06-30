
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
        self.cpuHalted = self.debugHalt = self.debugSingleStep = self.INTR = self.HRQ = False
        self.debugHalt = self.main.debugHalt
        self.savedSs = self.savedEsp = self.cycles = self.oldCycleInc = 0
        self.registers.reset()
    cdef inline void saveCurrentInstPointer(self):
        self.savedCs  = self.registers.segRead(CPU_SEGMENT_CS)
        self.savedEip = self.registers.regReadUnsignedDword(CPU_REGISTER_EIP)
        self.savedSs  = self.registers.segRead(CPU_SEGMENT_SS)
        self.savedEsp = self.registers.regReadUnsignedDword(CPU_REGISTER_ESP)
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
            self.cpuHalted = False
        return
    cpdef exception(self, unsigned char exceptionId, signed int errorCode=-1):
        self.main.notice("Running exception_1: exceptionId: {0:#04x}, errorCode: {1:#04x}", exceptionId, errorCode)
        self.cpuDump()
        #self.main.debugEnabled = True
        if (exceptionId in CPU_EXCEPTIONS_FAULT_GROUP):
            self.registers.segWriteSegment((<Segment>self.registers.segments.cs), self.savedCs)
            self.registers.regWriteDword(CPU_REGISTER_EIP, self.savedEip)
            self.registers.segWriteSegment((<Segment>self.registers.segments.ss), self.savedSs)
            self.registers.regWriteDword(CPU_REGISTER_ESP, self.savedEsp)
        #elif (exceptionId in CPU_EXCEPTIONS_TRAP_GROUP):
        #    self.savedEip = <unsigned int>(self.savedEip+1)
        if (exceptionId in CPU_EXCEPTIONS_FAULT_GROUP and exceptionId != CPU_EXCEPTION_DB):
            self.registers.rf = True
        elif (exceptionId in CPU_EXCEPTIONS_TRAP_GROUP and self.registers.repPrefix):
            self.registers.rf = True
        if (exceptionId in CPU_EXCEPTIONS_WITH_ERRORCODE):
            if (errorCode == -1):
                self.main.exitError("CPU exception: errorCode should be set, is -1.")
                return
            self.opcodes.interrupt(exceptionId, errorCode)
        else:
            self.opcodes.interrupt(exceptionId)
        self.main.notice("Running exception_2: exceptionId: {0:#04x}, errorCode: {1:#04x}", exceptionId, errorCode)
        self.cpuDump()
    cpdef handleException(self, object exception):
        cdef unsigned char exceptionId
        cdef signed int errorCode
        #if (self.savedCs == 0x70 and self.savedEip == 0x3b2):
        #if (self.savedCs == 0x70 and self.savedEip == 0x382):
        #    self.main.debugEnabled = True
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
    cdef unsigned char parsePrefixes(self, unsigned char opcode) except? BITMASK_BYTE:
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
                        self.registers.ssInhibit = False
                        if (self.main.platform.vga and self.main.platform.vga.ui):
                            self.main.platform.vga.ui.handleEventsWithoutWaiting()
                        sleep(0.2)
                    continue
                self.doCycle()
        except:
            print_exc()
            self.main.exitError('doInfiniteCycles: exception, exiting...')
    cpdef doCycle(self):
        #cdef unsigned int test1
        if (self.debugHalt and self.debugSingleStep):
            self.debugSingleStep = False
        #self.registers.reloadCpuCache()
        self.cycles += CPU_CLOCK_TICK
        self.registers.resetPrefixes()
        self.saveCurrentInstPointer()
        if (<unsigned short>self.cycles == 0x00):
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
            #if (self.savedEip == 0x476e0):
            #if (self.savedCs == 0x8 and self.savedEip == 0xe14d):
            #if (self.savedCs == 0xf and self.savedEip == 0x96d7):
            #if (self.savedCs == 0x28 and self.savedEip == 0xc0007870):
            #if (self.registers.segments.paging.tlbTables.csReadValueUnsigned(0x3fec04, OP_SIZE_DWORD) != 0):
            #if (self.savedCs == 0x2000 and self.savedEip == 0x1b66):
            #if (self.savedCs == 0xf and self.savedEip == 0x3d859):
            #if (self.savedCs == 0xb0):
            #if (self.savedCs == 0xa8):
            #if (self.savedCs == 0x28 and self.savedEip == 0xc00059c4):
            #if (self.savedCs == 0xffff and self.savedEip == 0x2ec):
            #if (self.savedCs == 0x28 and self.savedEip == 0xc0003780):
            #if (self.savedCs == 0x28 and self.savedEip == 0xc037a8f8):
            #if (self.savedCs == 0x28 and self.savedEip == 0xc00059ae and self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx == 0xffb04fbc):
            #if (self.savedCs == 0x28 and self.savedEip == 0xc00059ae and self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx == 0xffb04fb0):
            #if (self.savedCs == 0x28 and self.savedEip == 0xc0002570):
            #if (self.savedCs == 0x247 and self.savedEip == 0x6c):
            #    self.main.debugEnabled = True
            #elif (self.savedCs == 0x247 and self.savedEip == 0x6d):
            #    self.main.debugEnabled = False
            #if (self.savedCs == 0xfcbf and self.savedEip == 0x2f28 and self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx == 0x4100):
            #    self.main.debugEnabled = True
            #if (self.savedCs == 0x685 and self.savedEip == 0x3fd):
            #if (self.savedCs == 0x17 and self.savedEip == 0x1020):
            #if (self.savedCs == 0x8 and self.savedEip == 0xf01004e3):
            #if (self.savedCs == 0x8 and self.savedEip == 0xf0100661):
            #if (self.savedCs == 0x8 and self.savedEip == 0x80134706 and self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx == 0xc1024000):
            #if (self.savedCs == 0x8 and self.savedEip == 0x801990c2):
            #if (self.savedCs == 0x8 and self.savedEip == 0x80137faf and self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx == 0x801630e2):
            #if (self.savedCs == 0xff03 and self.savedEip == 0x52d0 and self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx == 0xbde2):
            #    self.main.debugEnabled = True
            #if (self.savedCs == 0xffff and self.savedEip == 0x25a5 and self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx == 0xc0010002):
            #    self.main.debugEnabled = True
            #if (self.savedCs == 0xffff and self.savedEip == 0x165b and self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx == 0xc0010002):
            #    self.main.debugEnabled = True
            #if (self.savedCs == 0xff03 and self.savedEip == 0x4266):
            #    self.main.debugEnabled = True
            #if (self.savedCs == 0x835 and self.savedEip == 0x18f5):
            #    self.main.debugEnabled = True
            #if (self.savedCs == 0x6a5 and self.savedEip == 0x4202):
            #    self.main.debugEnabled = True
            #if (self.savedCs == 0x835 and self.savedEip == 0x4202):
            #    self.main.debugEnabled = True
            #if (self.savedCs == 0x28 and self.savedEip == 0xc0007640 and self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx == 0x1f4):
            #    self.main.debugEnabled = True
            #if (self.savedCs == 0x8 and self.savedEip == 0x801ae979):
            #    self.main.debugEnabled = True
            #test1 = self.main.mm.mmPhyReadValueUnsignedDword(0xc0002f6f)
            if (self.main.debugEnabled):
            #if (self.main.debugEnabled or test1 != self.oldCycleInc):
            #IF 1:
                self.main.notice("Current Opcode: {0:#04x}; It's EIP: {1:#06x}, CS: {2:#06x}", self.opcode, self.savedEip, self.savedCs)
                #self.main.notice("Cpu::doCycle: test1 PDE[0x9bfef8]=={0:#010x}==0x009c8267", self.main.mm.mmPhyReadValueUnsignedDword(0x9bfef8))
                #self.main.notice("Cpu::doCycle: test2 PTE[0x9c8ff4]=={0:#010x}==0x00994025", self.main.mm.mmPhyReadValueUnsignedDword(0x9c8ff4))
                IF 0:
                    self.main.notice("Cpu::doCycle: test3.1 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x1f160))
                    self.main.notice("Cpu::doCycle: test3.2 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x1f164))
                    self.main.notice("Cpu::doCycle: test3.3 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x1f168))
                    self.main.notice("Cpu::doCycle: test3.4 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x1f16c))
                    self.main.notice("Cpu::doCycle: test4.1 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00ffffe0))
                    self.main.notice("Cpu::doCycle: test4.2 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00ffffe4))
                    self.main.notice("Cpu::doCycle: test4.3 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00ffffe8))
                    self.main.notice("Cpu::doCycle: test4.4 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00ffffec))
                    self.main.notice("Cpu::doCycle: test4.5 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00fffff0))
                    self.main.notice("Cpu::doCycle: test4.6 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00fffff4))
                    self.main.notice("Cpu::doCycle: test4.7 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00fffff8))
                    self.main.notice("Cpu::doCycle: test4.8 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00fffffc))
                #self.main.notice("Cpu::doCycle: test5.1 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00fff004))
                #self.main.notice("Cpu::doCycle: test6.1 {0:#010x}", self.registers.segments.paging.tlbTables.csReadValueUnsigned(0x3fec04, OP_SIZE_DWORD))
                #self.main.notice("Cpu::doCycle: test6.2 {0:#010x}", self.registers.segments.paging.tlbDirectories.csReadValueUnsigned(0xc00, OP_SIZE_DWORD))
                #self.main.notice("Cpu::doCycle: test6.3 {0:#010x}", self.registers.segments.paging.tlbTables.csReadValueUnsigned(0x300878, OP_SIZE_DWORD))
                #self.main.notice("Cpu::doCycle: test7.1 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x00375f9c))
                #self.main.notice("Cpu::doCycle: test7.2 {0:#010x}", test1)
                #self.main.notice("Cpu::doCycle: test8.1 {0:#010x}", self.main.mm.mmPhyReadValueUnsignedDword(0x1ae9c1))
                self.cpuDump()
                #self.main.notice("CR0: {0:#010x}", self.registers.regReadUnsignedDword(CPU_REGISTER_CR0))
                #self.oldCycleInc = test1
                #self.main.debugEnabled = True
                #self.main.debugEnabled = False
            #else:
            #    self.main.debugEnabled = False
            if (not self.opcodes.executeOpcode(self.opcode)):
                self.main.notice("Opcode not found. (opcode: {0:#04x}; EIP: {1:#06x}, CS: {2:#06x})", self.opcode, self.savedEip, self.savedCs)
                raise HirnwichseException(CPU_EXCEPTION_UD)
        except HirnwichseException as exception: # exception
            self.main.notice("Cpu::doCycle: testexc1")
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

