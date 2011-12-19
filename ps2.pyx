
# This file contains code from The Bochs Project. Thanks to them!

import time

from registers cimport Registers
from pic cimport Pic


include "globals.pxi"
include "kb_scancodes.pxi"

DEF PPCB_T2BOTH = 0x03
DEF PPCB_T2OUT = 0x20

DEF PS2_CPU_RESET = 0x01
DEF PS2_A20 = 0x02
DEF PS2_CMDBYTE_IRQ1 = 0x01

cdef class PS2:
    def __init__(self, object main):
        self.main = main
    cdef resetInternals(self, unsigned char powerUp):
        self.outBuffer  = bytes() # KBC -> CPU
        self.needWriteBytes = 0 # need to write $N bytes to 0x60
        self.currentScancodesSet = 1 # MF2
        if (powerUp):
            self.setKeyboardRepeatRate(0x2a)
    cdef initDevice(self):
        self.resetInternals(True)
        self.lastUsedPort = True # 0==0x60; 1==(0x61 or 0x64)
        self.ppcbT2Both = False
        self.ppcbT2Out = False
        self.kbdClockEnabled = True
        self.irq1Requested = False
        self.allowIrq1 = True
        self.sysf = False
        self.lastKbcCmdByte = 0
        self.lastKbCmdByte = 0
        self.translateScancodes = True
        self.scanningEnabled = True
        self.outb = False
        self.batInProgress = False
        self.timerPending = 0
    cdef appendToOutBytesJustAppend(self, bytes data):
        self.outBuffer += data
    cdef appendToOutBytes(self, bytes data):
        self.appendToOutBytesJustAppend(data)
        if (not self.outb and self.kbdClockEnabled):
            self.activateTimer()
    cdef appendToOutBytesImm(self, bytes data):
        self.appendToOutBytesJustAppend(data)
        self.outb = True
        if (self.allowIrq1):
            self.irq1Requested = True
            (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
    cdef appendToOutBytesDoIrq(self, bytes data):
        if (self.outb):
            self.main.printMsg("KBC::appendToOutBytesDoIrq: self.outb!=0")
            return
        self.appendToOutBytesJustAppend(data)
        self.outb = True
        if (self.allowIrq1):
            self.irq1Requested = True
            (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
    cdef setKeyboardRepeatRate(self, unsigned char data): # input is data from cmd 0xf3
        cdef unsigned short delay, interval
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
            self.main.exitError("setKeyboardRepeatRate: interval {0:d} unknown.", interval)
        if (self.main.platform.vga.ui is not None):
            self.main.platform.vga.ui.setRepeatRate(delay, interval)
    cdef keySend(self, unsigned char keyId, unsigned char keyUp):
        cdef unsigned char escaped, sc
        cdef bytes scancode
        escaped = 0x00
        self.main.debug("PS2::keySend entered. (keyId: {0:#04x}, keyUp: {1:d})", keyId, keyUp)
        if ((not self.kbdClockEnabled) or (not self.scanningEnabled) or (keyId == 0xff)):
            return
        self.main.debug("PS2::keySend: send key. (keyId: {0:#04x}, keyUp: {1:d})", keyId, keyUp)
        scancode = SCANCODES[keyId][self.currentScancodesSet][keyUp]
        if (self.translateScancodes):
            for sc in scancode:
                if (sc == 0xf0):
                    escaped = 0x80
                else:
                    self.appendToOutBytesJustAppend( bytes([( TRANSLATION_8042[sc] | escaped )]) )
                    escaped = 0x00
        else:
            self.appendToOutBytesJustAppend(scancode)
        self.outb = True
        if (self.allowIrq1 and self.kbdClockEnabled):
            self.irq1Requested = True
            (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
        ###self.activateTimer()
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char retByte = 0
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x64):
                if (len(self.outBuffer)):
                    self.outb = True # TODO: HACK
                    #if (self.allowIrq1): # TODO: delete this again!?!
                    #    self.irq1Requested = True
                    #    (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
                return ((0x10) | \
                       (self.lastUsedPort << 3) | \
                       (self.sysf << 2) | \
                       (self.outb))
            elif (ioPortAddr == 0x60):
                self.outb = False
                self.irq1Requested = False
                self.batInProgress = False
                (<Pic>self.main.platform.pic).lowerIrq(KBC_IRQ)
                if (len(self.outBuffer)):
                    retByte = self.outBuffer[0]
                    if (len(self.outBuffer) > 1):
                        self.outBuffer = self.outBuffer[1:]
                        self.outb = True
                        if (self.allowIrq1):
                            self.irq1Requested = True
                            (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
                    else:
                        self.outBuffer = bytes()
                #(<Pic>self.main.platform.pic).lowerIrq(KBC_IRQ)
                #if (len(self.outBuffer)):
                #    self.activateTimer()
                return retByte
            elif (ioPortAddr == 0x61):
                return (self.ppcbT2Both and PPCB_T2BOTH) | \
                       (self.ppcbT2Out and PPCB_T2OUT)
            elif (ioPortAddr == 0x92):
                return ((<Registers>self.main.cpu.registers).getA20State() << 1)
            else:
                self.main.exitError("inPort: port {0:#04x} is not supported.", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x60):
                if (not self.needWriteBytes):
                    self.lastKbcCmdByte, self.lastKbCmdByte = 0, data
                    if (not self.kbdClockEnabled):
                        self.setKbdClockEnable(True)
                    if (data == 0x00):
                        self.appendToOutBytes(b'\xfa')
                    elif (data == 0x05):
                        self.sysf = True
                        self.appendToOutBytesImm(b'\xfe')
                    elif (data == 0xd3):
                        self.appendToOutBytes(b'\xfa')
                    elif (data == 0xed):
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
                        self.main.exitError("KBD: got resend cmd, maybe it's better to check for bugs in ps2.pyx. exiting...")
                    elif (data == 0xff):
                        self.resetInternals(True)
                        self.appendToOutBytes(b'\xfa')
                        self.batInProgress = True
                        self.appendToOutBytes(b'\xaa')
                    elif (data in (0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd)):
                        self.appendToOutBytes(b'\xfe')
                    else:
                        self.main.printMsg("outPort: data {0:#04x} is not supported. (port {1:#04x})", data, ioPortAddr)
                else:
                    if (self.lastKbcCmdByte == 0xd1): # port 0x64
                        (<Registers>self.main.cpu.registers).setA20State( (data & PS2_A20) != 0 )
                        if (not (data & PS2_CPU_RESET)):
                            self.main.cpu.reset()
                    elif (self.lastKbcCmdByte == 0x60): # port 0x64
                        self.translateScancodes = (data >> 6)&1
                        self.setKbdClockEnable(not ((data >> 4)&1))
                        self.sysf = (data >> 2)&1
                        self.allowIrq1 = data&1
                        if (self.allowIrq1 and self.outb):
                            self.irq1Requested = True
                            (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
                    elif (self.lastKbCmdByte == 0xf0): # port 0x60
                        if (data == 0x00): # get scancodes
                            self.appendToOutBytes(b'\xfa')
                            self.appendToOutBytes(bytes([ self.currentScancodesSet+1 ]))
                        elif (data in (0x01, 0x02, 0x03)):
                            self.currentScancodesSet = data-1
                            self.appendToOutBytes(b'\xfa')
                        else:
                            self.appendToOutBytes(b'\xff')
                    elif (self.lastKbCmdByte == 0xf3): # port 0x60
                        self.appendToOutBytes(b'\xfa')
                    elif (self.lastKbCmdByte == 0xed): # port 0x60
                        self.appendToOutBytes(b'\xfa')
                    else:
                        self.main.printMsg("outPort: data {0:#04x} is not supported. (port {1:#04x}, needWriteBytes=={2:d}, lastKbcCmdByte=={3:#04x}, lastKbCmdByte=={4:#04x})", data, ioPortAddr, self.needWriteBytes, self.lastKbcCmdByte, self.lastKbCmdByte)
                    self.needWriteBytes -= 1
            elif (ioPortAddr == 0x64):
                self.lastKbcCmdByte, self.lastKbCmdByte = data, 0
                if (data == 0x20): # read keyboard mode
                    if (self.outb):
                        self.main.printMsg("ERROR: KBC::outPort: Port 0x64, data 0x20: outb is set.")
                        return
                    self.appendToOutBytesDoIrq(bytes([( \
                    (self.translateScancodes << 6) | \
                    (self.kbdClockEnabled << 4) | \
                    (self.sysf << 2) | \
                    (self.allowIrq1) )]))
                elif (data == 0x60): # write keyboard mode
                    self.needWriteBytes = 1
                elif (data in (0xa7, 0xa8, 0xa9)): # 0xa7: disable mouse, 0xa8: enable mouse, 0xa9: test mouse port
                    self.main.printMsg("PS2::outPort: mouse isn't supported yet. (data: {0:#04x})", data)
                    self.appendToOutBytes(b'\xfe')
                elif (data == 0xaa):
                    self.outBuffer = bytes()
                    self.outb = False
                    self.sysf = True
                    self.appendToOutBytesDoIrq(b'\x55')
                elif (data == 0xab):
                    if (self.outb):
                        self.main.printMsg("ERROR: KBC::outPort: Port 0x64, data 0xab: outb is set.")
                        return
                    self.appendToOutBytesDoIrq(b'\x00')
                elif (data == 0xad): # disable keyboard
                    self.setKbdClockEnable(False)
                elif (data == 0xae): # enable keyboard
                    self.setKbdClockEnable(True)
                elif (data == 0xd0):
                    if (self.outb):
                        self.main.exitError("ERROR: KBC::outPort: Port 0x64, data 0xd0: outb is set.")
                        return
                    outputByte = ((self.irq1Requested << 4) | ((<Registers>self.main.cpu.registers).getA20State() << 1) | 0x01)
                    self.appendToOutBytesDoIrq(bytes([outputByte]))
                elif (data == 0xd1):
                    self.needWriteBytes = 1
                elif (data == 0xdd):
                    (<Registers>self.main.cpu.registers).setA20State( False )
                elif (data == 0xdf):
                    (<Registers>self.main.cpu.registers).setA20State( True )
                elif (data == 0xfe): # reset cpu
                    self.main.cpu.reset()
                elif ((data >= 0xf0 and data <= 0xfd) or data == 0xff):
                    self.main.debug("outPort: ignoring useless command {0:#04x}. (port {1:#04x})", data, ioPortAddr)
                else:
                    self.main.printMsg("outPort: data {0:#04x} is not supported. (port {1:#04x})", data, ioPortAddr)
            elif (ioPortAddr == 0x61):
                self.ppcbT2Both = (data&PPCB_T2BOTH)!=0
                self.ppcbT2Out = (data&PPCB_T2OUT)!=0
            elif (ioPortAddr == 0x92):
                (<Registers>self.main.cpu.registers).setA20State( (data & PS2_A20) != 0 )
            else:
                self.main.exitError("outPort: port {0:#04x} is not supported. (data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cdef setKbdClockEnable(self, unsigned char value):
        cdef unsigned char prevKbdClockEnabled
        if (not value):
            self.kbdClockEnabled = False
        else:
            prevKbdClockEnabled = self.kbdClockEnabled
            self.kbdClockEnabled = True
            if (not prevKbdClockEnabled and not self.outb):
                self.activateTimer()
    cdef activateTimer(self):
        if (not self.timerPending):
            self.timerPending = 1
    cdef unsigned char periodic(self, unsigned char usecDelta):
        cdef unsigned char retVal
        retVal = self.irq1Requested
        self.irq1Requested = False
        if (not self.timerPending):
            return retVal
        if (usecDelta >= self.timerPending):
            self.timerPending = 0
        else:
            self.timerPending -= usecDelta
            return retVal
        if (self.outb):
            return retVal
        if (len(self.outBuffer) and (self.kbdClockEnabled or self.batInProgress)):
            self.outb = True
            if (self.allowIrq1):
                self.irq1Requested = True
        return retVal
    cpdef timerFunc(self):
        cdef unsigned char retVal
        while (not self.main.quitEmu):
            if (self.timerPending):
                retVal = self.periodic(1)
                if (retVal&1):
                    (<Pic>self.main.platform.pic).raiseIrq(KBC_IRQ)
            else:
                time.sleep(0.02)
    cpdef initThread(self):
        self.main.misc.createThread(self.timerFunc, True)
    cdef run(self):
        self.initDevice()
        self.initThread()
        #self.main.platform.addHandlers((0x60, 0x61, 0x64, 0x92), self)


