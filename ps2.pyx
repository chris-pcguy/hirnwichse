
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

# This file contains code from The Bochs Project. Thanks to them!

include "globals.pxi"
include "kb_scancodes.pxi"

from time import sleep, time
from traceback import print_exc

DEF KBC_IRQ = 1 # keyboard controller's IRQnum
DEF MOUSE_IRQ = 12 # mouse IRQnum
DEF TIMER_IRQ = 0

DEF PS2_CPU_RESET = 0x01
DEF PS2_A20 = 0x02
DEF PS2_CMDBYTE_IRQ1 = 0x01

cdef class PS2:
    def __init__(self, Hirnwichse main):
        self.main = main
    cdef void resetInternals(self, uint8_t powerUp) nogil:
        with gil:
            self.outBuffer  = bytes() # KBC -> CPU
            self.mouseBuffer = bytes() # CPU -> MOUSE
        self.needWriteBytes = 0 # need to write $N bytes to 0x60
        self.needWriteBytesMouse = 0
        self.currentScancodesSet = 1 # MF2
        ##if (powerUp):
        ##    self.setKeyboardRepeatRate(0x2a) # do this in pygameUI.pyx instead!!
    cdef void initDevice(self) nogil:
        self.resetInternals(True)
        self.lastUsedPort = self.lastUsedCmd = 0
        self.lastUsedController = True # 0x64
        self.ppcbT2Gate = self.ppcbT2Spkr = self.ppcbT2Out = False
        self.irq1Requested = self.irq12Requested = self.sysf = False
        self.outb = self.inb = self.auxb = self.batInProgress = self.timeout = False
        self.kbdClockEnabled = self.allowIrq1 = True
        self.translateScancodes = self.scanningEnabled = True
        self.timerPending = 0
        self.allowIrq12 = False
    cdef void appendToOutBytesJustAppend(self, bytes data) nogil:
        with gil:
            self.outBuffer += data
        self.outb = True
    cdef void appendToOutBytesMouse(self, bytes data) nogil:
        with gil:
            self.mouseBuffer += data
        self.auxb = self.outb = True
    cdef void appendToOutBytes(self, bytes data) nogil:
        self.appendToOutBytesJustAppend(data)
        #if (not self.outb and self.kbdClockEnabled):
        if (self.kbdClockEnabled):
            self.activateTimer()
    cdef void appendToOutBytesImm(self, bytes data) nogil:
        #self.appendToOutBytesJustAppend(data)
        self.appendToOutBytes(data)
        self.outb = True
        if (self.allowIrq1):
            self.irq1Requested = True
            (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
    cdef void appendToOutBytesDoIrq(self, bytes data) nogil:
        if (self.outb):
            with gil:
                self.main.notice("KBC::appendToOutBytesDoIrq: self.outb!=0")
            return
        self.appendToOutBytesImm(data)
    cdef void setKeyboardRepeatRate(self, uint8_t data) nogil: # input is data from cmd 0xf3
        cdef uint16_t delay, interval
        interval = data&0x1f
        delay = ((data&0x60)>>5)&3
        delay = (delay+1)*250 # delay in milliseconds
        if (interval == 0): interval = 33
        elif (interval == 1): interval = 37
        elif (interval == 2): interval = 41
        elif (interval == 4): interval = 50
        elif (interval == 8): interval = 66
        elif (interval == 0xa): interval = 100
        elif (interval == 0xd): interval = 111
        elif (interval == 0x10): interval = 133
        elif (interval == 0x14): interval = 200
        elif (interval == 0x1f): interval = 500
        else:
            with gil:
                self.main.exitError("setKeyboardRepeatRate: interval {0:d} unknown.", interval)
        # TODO: Set the repeat-rate properly.
        if (self.main.platform.vga.ui is not None):
            with gil:
                self.main.platform.vga.ui.setRepeatRate(delay, interval)
    cdef void keySend(self, uint8_t keyId, uint8_t keyUp):
        cdef uint8_t sc, escaped
        cdef bytes scancode, returnedScancode
        self.main.notice("PS2::keySend entered. (keyId: {0:#04x}, keyUp: {1:d})", keyId, keyUp)
        if ((not self.kbdClockEnabled) or (not self.scanningEnabled) or (keyId == 0xff)):
            return
        self.main.notice("PS2::keySend: send key. (keyId: {0:#04x}, keyUp: {1:d})", keyId, keyUp)
        scancode = SCANCODES[keyId][self.currentScancodesSet][keyUp]
        if (self.translateScancodes):
            returnedScancode = b""
            escaped = 0x00
            for sc in scancode:
                if (sc == 0xf0):
                    escaped = 0x80
                else:
                    returnedScancode += bytes([ TRANSLATION_8042[sc] | escaped ])
                    escaped = 0x00
            self.appendToOutBytesImm( returnedScancode )
        else:
            self.appendToOutBytesImm(scancode)
        ##self.outb = True
        ##if (self.allowIrq1 and self.kbdClockEnabled):
        ##    self.irq1Requested = True
        ##    (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
        #self.activateTimer()
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil:
        cdef uint8_t retByte
        retByte = 0
        if (dataSize == OP_SIZE_BYTE):
            #if (ioPortAddr != 0x64):
            IF COMP_DEBUG:
                with gil:
                    self.main.notice("PS2: inPort_1: port {0:#04x}; savedCs=={1:#06x}; savedEip=={2:#06x}", ioPortAddr, (<Cpu>self.main.cpu).savedCs, (<Cpu>self.main.cpu).savedEip)
            if (ioPortAddr == 0x64):
                #if (len(self.mouseBuffer)):
                #    self.auxb = True # TODO: HACK
                #    self.outb = True # TODO: HACK
                #elif (len(self.outBuffer)):
                #    self.outb = True # TODO: HACK
                #    #if (self.allowIrq1): # TODO: delete this again!?!
                #    #    self.irq1Requested = True
                #    #    (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
                with gil:
                    self.auxb = len(self.mouseBuffer)!=0 # TODO: HACK
                    self.outb = len(self.outBuffer)!=0 or len(self.mouseBuffer)!=0 # TODO: HACK
                retByte = (0x10 | \
                        (self.timeout << 6) | \
                        (self.auxb << 5) | \
                        (self.lastUsedController << 3) | \
                        (self.sysf << 2) | \
                        (self.inb << 1) | \
                        self.outb)
                self.timeout = False
                #if (self.main.debugEnabled):
                #    self.main.debug("PS2: inPort_2: port {0:#04x}; retByte {1:#04x}", ioPortAddr, retByte)
                IF COMP_DEBUG:
                    with gil:
                        self.main.notice("PS2: inPort_2: port {0:#04x}; retByte {1:#04x}", ioPortAddr, retByte)
                return retByte
            elif (ioPortAddr == 0x60):
                #self.outb = False
                #self.auxb = False
                #self.irq1Requested = False
                #self.irq12Requested = False
                self.batInProgress = False
                (<Pic>self.main.platform.pic).lowerIrq(MOUSE_IRQ)
                (<Pic>self.main.platform.pic).lowerIrq(KBC_IRQ)
                #with nogil:
                #    usleep(50)
                with gil:
                    if (len(self.mouseBuffer)):
                        retByte = self.mouseBuffer[0]
                        if (len(self.mouseBuffer) > 1):
                            self.mouseBuffer = self.mouseBuffer[1:]
                            self.auxb = True
                            if (self.allowIrq12):
                                self.irq12Requested = True
                                (<Pic>self.main.platform.pic).raiseIrq(MOUSE_IRQ)
                        else:
                            self.mouseBuffer = bytes()
                            self.auxb = False
                            self.irq12Requested = False
                    elif (len(self.outBuffer)):
                        retByte = self.outBuffer[0]
                        if (len(self.outBuffer) > 1):
                            self.outBuffer = self.outBuffer[1:]
                            self.outb = True
                            if (self.allowIrq1):
                                self.irq1Requested = True
                                (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
                        else:
                            self.outBuffer = bytes()
                            self.outb = False
                            self.irq1Requested = False
                #(<Pic>self.main.platform.pic).lowerIrq(KBC_IRQ)
                #if (len(self.outBuffer)):
                #    self.activateTimer()
                #if (self.main.debugEnabled):
                #    self.main.debug("PS2: inPort_3: port {0:#04x}; retByte {1:#04x}", ioPortAddr, retByte)
                IF COMP_DEBUG:
                    with gil:
                        self.main.notice("PS2: inPort_3: port {0:#04x}; retByte {1:#04x}", ioPortAddr, retByte)
                return retByte
            elif (ioPortAddr == 0x61):
                with gil:
                    retByte = ((((int(time()*1e7) & 0xf) == 0) << 4) | \
                        (self.ppcbT2Gate and PPCB_T2_GATE) | \
                        (self.ppcbT2Spkr and PPCB_T2_SPKR) | \
                        (self.ppcbT2Out  and PPCB_T2_OUT))
                IF COMP_DEBUG:
                    with gil:
                        self.main.notice("PS2: inPort_4: port {0:#04x}; retByte {1:#04x}", ioPortAddr, retByte)
                return retByte
            elif (ioPortAddr == 0x92):
                return ((<Registers>(<Cpu>self.main.cpu).registers).A20Active << 1)
            else:
                with gil:
                    self.main.exitError("inPort: port {0:#04x} is not supported.", ioPortAddr)
        else:
            with gil:
                self.main.exitError("inPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        return 0
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil:
        if (dataSize == OP_SIZE_BYTE):
            IF COMP_DEBUG:
                with gil:
                    self.main.notice("PS2: outPort: port {0:#04x} ; data {1:#04x}; savedCs=={2:#06x}; savedEip=={3:#06x}", ioPortAddr, data, (<Cpu>self.main.cpu).savedCs, (<Cpu>self.main.cpu).savedEip)
            if (ioPortAddr == 0x60):
                self.lastUsedController = False
                if (not self.needWriteBytes):
                    if (not self.kbdClockEnabled):
                        self.setKbdClockEnable(True)
                    if (data == 0x00):
                        self.appendToOutBytesImm(b'\xfa')
                    elif (data == 0x05):
                        self.sysf = True
                        self.appendToOutBytesImm(b'\xfe')
                    elif (data == 0xd3):
                        self.appendToOutBytes(b'\xfa')
                    elif (data == 0xed): # setLeds
                        self.needWriteBytes = 1
                        self.appendToOutBytesImm(b'\xfa')
                    elif (data == 0xee):
                        self.appendToOutBytes(b'\xee')
                    elif (data == 0xf0): # set scancodes
                        self.needWriteBytes = 1
                        self.appendToOutBytes(b'\xfa')
                    elif (data == 0xf2):
                        self.appendToOutBytes(b'\xfa')
                        self.appendToOutBytes(b'\xab')
                        if (self.translateScancodes):
                            self.appendToOutBytes(b'\x41')
                        else:
                            self.appendToOutBytes(b'\x83')
                    elif (data == 0xf3): # set repeat rate
                        self.needWriteBytes = 1
                        self.appendToOutBytes(b'\xfa')
                    elif (data == 0xf4):
                        self.scanningEnabled = True
                        self.appendToOutBytes(b'\xfa')
                    elif (data == 0xf5):
                        self.resetInternals(True)
                        self.appendToOutBytes(b'\xfa')
                        self.scanningEnabled = False
                    elif (data == 0xf6): # load default
                        self.resetInternals(True)
                        self.appendToOutBytes(b'\xfa')
                        self.scanningEnabled = True
                    elif (data == 0xfe): # got resend cmd
                        with gil:
                            self.main.exitError("KBD: got resend cmd, maybe it's better to check for bugs in ps2.pyx. exiting...")
                    elif (data == 0xff):
                        self.resetInternals(True)
                        self.appendToOutBytes(b'\xfa')
                        self.batInProgress = True
                        self.appendToOutBytes(b'\xaa')
                    elif (data in (0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd)):
                        self.appendToOutBytes(b'\xfe')
                    else:
                        with gil:
                            self.main.notice("outPort: data {0:#04x} is not supported. (port {1:#04x})", data, ioPortAddr)
                    if (self.needWriteBytes > 0):
                        self.lastUsedPort = ioPortAddr
                        self.lastUsedCmd = data
                else:
                    if (self.lastUsedPort == 0x64):
                        if (self.lastUsedCmd == 0xd1): # port 0x64
                            (<Registers>(<Cpu>self.main.cpu).registers).setA20Active( (data & PS2_A20) != 0 )
                            if (not (data & PS2_CPU_RESET)):
                                with gil:
                                    (<Cpu>self.main.cpu).reset()
                        elif (self.lastUsedCmd == 0xd2): # port 0x64
                            with gil:
                                self.appendToOutBytesImm(bytes([data]))
                        elif (self.lastUsedCmd == 0xd3): # port 0x64
                            with gil:
                                self.appendToOutBytesMouse(bytes([data]))
                        elif (self.lastUsedCmd == 0xd4): # port 0x64
                            #if (self.main.debugEnabled):
                            IF 0:
                                with gil:
                                    self.main.notice("outPort: self.lastUsedPort == 0x64; self.lastUsedCmd == 0xd4. (port {0:#04x}; data {1:#04x}; self.needWriteBytesMouse {2:d})", ioPortAddr, data, self.needWriteBytesMouse)
                            IF 0:
                            #IF 1: # mouse present
                                self.appendToOutBytesMouse(b'\xfa')
                                if (self.needWriteBytesMouse > 0):
                                    self.needWriteBytesMouse -= 1
                                else:
                                    if (data == 0xf2):
                                        self.appendToOutBytesMouse(b'\x00')
                                    elif (data == 0xf3):
                                        self.needWriteBytesMouse = 1
                                    elif (data == 0xff):
                                        self.appendToOutBytesMouse(b'\xaa\x00')
                            ELSE:
                                self.appendToOutBytesMouse(b'\xfe')
                                self.timeout = True
                        elif (self.lastUsedCmd == 0x60): # port 0x64
                            self.translateScancodes = (data >> 6)&1
                            self.setKbdClockEnable(not ((data >> 4)&1))
                            self.sysf = (data >> 2)&1
                            self.allowIrq1 = data&1
                            if (self.allowIrq1 and self.outb):
                                self.irq1Requested = True
                                (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
                        else:
                            with gil:
                                self.main.exitError("outPort: data_3 {0:#04x} is not supported. (port {1:#04x}, needWriteBytes=={2:d}, lastUsedPort=={3:#04x}, lastUsedCmd=={4:#04x})", data, ioPortAddr, self.needWriteBytes, self.lastUsedPort, self.lastUsedCmd)
                    elif (self.lastUsedPort == 0x60):
                        if (self.lastUsedCmd == 0xf0): # port 0x60
                            if (data == 0x00): # get scancodes
                                with gil:
                                    self.appendToOutBytes(bytes([ 0xfa, self.currentScancodesSet+1 ]))
                            elif (data in (0x01, 0x02, 0x03)):
                                self.currentScancodesSet = data-1
                                with gil:
                                    self.main.notice("outPort: self.currentScancodesSet is now set to {0:d}. (port {1:#04x}; data {2:#04x})", self.currentScancodesSet, ioPortAddr, data)
                                self.appendToOutBytes(b'\xfa')
                            else:
                                self.appendToOutBytes(b'\xff')
                        elif (self.lastUsedCmd == 0xf3): # port 0x60
                            self.appendToOutBytes(b'\xfa')
                        elif (self.lastUsedCmd == 0xed): # port 0x60; setLeds
                            self.appendToOutBytesImm(b'\xfa')
                        else:
                            with gil:
                                self.main.exitError("outPort: data_2 {0:#04x} is not supported. (port {1:#04x}, needWriteBytes=={2:d}, lastUsedPort=={3:#04x}, lastUsedCmd=={4:#04x})", data, ioPortAddr, self.needWriteBytes, self.lastUsedPort, self.lastUsedCmd)
                    elif (self.lastUsedPort):
                        with gil:
                            self.main.exitError("outPort: data_1 {0:#04x} is not supported. (port {1:#04x}, needWriteBytes=={2:d}, lastUsedPort=={3:#04x}, lastUsedCmd=={4:#04x})", data, ioPortAddr, self.needWriteBytes, self.lastUsedPort, self.lastUsedCmd)
                    self.needWriteBytes -= 1
                    if (not self.needWriteBytes):
                        self.lastUsedPort = self.lastUsedCmd = 0
            elif (ioPortAddr == 0x64):
                self.lastUsedController = True
                if (data == 0x20): # read keyboard mode
                    if (self.outb):
                        with gil:
                            self.main.notice("ERROR: KBC::outPort: Port 0x64, data 0x20: outb is set.")
                        return
                    with gil:
                        self.appendToOutBytes(bytes([( \
                            (self.translateScancodes << 6) | \
                            (1 << 5) | \
                            ((not self.kbdClockEnabled) << 4) | \
                            (self.sysf << 2) | \
                            (self.allowIrq1) )]))
                elif (data == 0x60): # write keyboard mode
                    self.needWriteBytes = 1
                elif (data == 0xa4): # check if password is set
                    self.appendToOutBytesImm(b'\xf1') # no password is set
                elif (data in (0xa7, 0xa8, 0xa9)): # 0xa7: disable mouse, 0xa8: enable mouse, 0xa9: test mouse port
                    with gil:
                        self.main.notice("PS2::outPort: mouse isn't supported yet. (data: {0:#04x})", data)
                    if (data == 0xa9):
                        self.appendToOutBytes(b'\x00') # return success anyway
                elif (data == 0xaa):
                    with gil:
                        self.outBuffer = bytes()
                        self.mouseBuffer = bytes()
                    self.outb = False
                    self.auxb = False
                    self.sysf = True
                    self.appendToOutBytesImm(b'\x55')
                elif (data == 0xab):
                    if (self.outb):
                        with gil:
                            self.main.notice("ERROR: KBC::outPort: Port 0x64, data 0xab: outb is set.")
                        return
                    self.appendToOutBytesImm(b'\x00')
                elif (data == 0xad): # disable keyboard
                    self.setKbdClockEnable(False)
                elif (data == 0xae): # enable keyboard
                    self.setKbdClockEnable(True)
                elif (data == 0xd0):
                    if (self.outb):
                        with gil:
                            self.main.exitError("ERROR: KBC::outPort: Port 0x64, data 0xd0: outb is set.")
                        return
                    outputByte = ((self.irq1Requested << 4) | ((<Registers>(<Cpu>self.main.cpu).registers).A20Active << 1) | 0x01)
                    with gil:
                        self.appendToOutBytesImm(bytes([outputByte]))
                elif (data >= 0xd1 and data <= 0xd4):
                    self.needWriteBytes = 1
                elif (data == 0xdd):
                    (<Registers>(<Cpu>self.main.cpu).registers).setA20Active(False)
                elif (data == 0xdf):
                    (<Registers>(<Cpu>self.main.cpu).registers).setA20Active(True)
                elif (data == 0xfe): # reset cpu
                    with gil:
                        (<Cpu>self.main.cpu).reset()
                elif ((data >= 0xf0 and data <= 0xfd) or data == 0xff):
                    pass
                    ##self.main.debug("outPort: ignoring useless command {0:#04x}. (port {1:#04x})", data, ioPortAddr)
                else:
                    with gil:
                        self.main.notice("outPort: data {0:#04x} is not supported. (port {1:#04x})", data, ioPortAddr)
                if (self.needWriteBytes > 0):
                    self.lastUsedPort = ioPortAddr
                    self.lastUsedCmd = data
                else:
                    self.lastUsedPort = self.lastUsedCmd = 0
            elif (ioPortAddr == 0x61):
                if (data & PORT_61H_LOWER_TIMER_IRQ):
                    with gil:
                        self.main.notice("PS2::outPort: timer lowerIrq")
                    (<Pic>self.main.platform.pic).lowerIrq(TIMER_IRQ)
                #else:
                #    (<Pic>self.main.platform.pic).raiseIrq(TIMER_IRQ)
                self.ppcbT2Gate = (data & PPCB_T2_GATE) != 0
                self.ppcbT2Spkr = (data & PPCB_T2_SPKR) != 0
                self.ppcbT2Out  = (data & PPCB_T2_OUT)  != 0
            elif (ioPortAddr == 0x92):
                (<Registers>(<Cpu>self.main.cpu).registers).setA20Active( (data & PS2_A20) != 0 )
            else:
                with gil:
                    self.main.exitError("outPort: port {0:#04x} is not supported. (data {1:#04x})", ioPortAddr, data)
        else:
            with gil:
                self.main.exitError("outPort: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", ioPortAddr, dataSize, data)
        return
    cdef void setKbdClockEnable(self, uint8_t value) nogil:
        cdef uint8_t prevKbdClockEnabled
        if (not value):
            self.kbdClockEnabled = False
        else:
            prevKbdClockEnabled = self.kbdClockEnabled
            self.kbdClockEnabled = True
            #if (not prevKbdClockEnabled and not self.outb):
            self.activateTimer()
    cdef void activateTimer(self) nogil:
        if (not self.timerPending):
            self.timerPending = 1
    cpdef uint8_t periodic(self, uint8_t usecDelta):
        cdef uint8_t retVal
        retVal = self.irq1Requested
        self.irq1Requested = False
        if (not self.timerPending):
            #self.main.notice("PS2::periodic: test1")
            return retVal
        if (usecDelta >= self.timerPending):
            self.timerPending = 0
        else:
            self.timerPending -= usecDelta
            #self.main.notice("PS2::periodic: test2")
            return retVal
        if (self.outb):
            #self.main.notice("PS2::periodic: test3")
            return retVal
        if (len(self.outBuffer) and (self.kbdClockEnabled or self.batInProgress)):
            self.outb = True
            if (self.allowIrq1):
                self.irq1Requested = True
        #self.main.notice("PS2::periodic: test4; retVal=={0:#04x}", retVal)
        return retVal
    cpdef timerFunc(self):
        cdef uint8_t retVal
        while (not self.main.quitEmu):
            if (self.timerPending):
                retVal = self.periodic(1)
                if (retVal&1):
                #if (retVal&1 or self.irq1Requested):
                    (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
            elif (len(self.outBuffer) and (self.kbdClockEnabled or self.batInProgress) and self.allowIrq1):
            #elif (self.irq1Requested):
                (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
            #else:
            if (len(self.outBuffer)):
                sleep(0.02)
                self.timerPending = True
            else:
                sleep(1)
    cpdef initThread(self):
        self.main.misc.createThread(self.timerFunc, True)
    cpdef run(self):
        try:
            self.initDevice()
            self.initThread()
        except:
            print_exc()
            self.main.exitError('run: exception, exiting...')


