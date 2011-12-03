
# This file contains code from The Bochs Project. Thanks to them!

import time

include "globals.pxi"
include "kb_scancodes.pxi"

DEF PPCB_T2BOTH = 0x03
DEF PPCB_T2OUT = 0x20

DEF PS2_CPU_RESET = 0x01
DEF PS2_A20 = 0x02
DEF PS2_CMDBYTE_IRQ1 = 0x01

cdef class PS2:
    cpdef object main
    cdef public unsigned char ppcbT2Both, ppcbT2Out, kbdClockEnabled
    cdef unsigned char lastUsedPort, needWriteBytes, lastKbcCmdByte, lastKbCmdByte, irq1Requested, allowIrq1, \
                        sysf, translateScancodes, currentScancodesSet, scanningEnabled
    cdef bytes outBuffer, inBuffer,  ctrlBuffer
    def __init__(self, object main):
        self.main = main
    cpdef resetInternals(self, unsigned char powerUp):
        self.outBuffer  = bytes() # KBC -> CPU
        self.ctrlBuffer = bytes() # KBC -> CPU
        self.inBuffer   = bytes() # CPU -> KBC
        self.needWriteBytes = 0 # need to write $N bytes to 0x60
        self.currentScancodesSet = 1 # MF2
        if (powerUp):
            self.setKeyboardRepeatRate(0x2a)
    cpdef initDevice(self):
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
    cpdef doKbcIrq(self):
        cdef unsigned char irq1WasRequested
        irq1WasRequested = self.irq1Requested
        self.irq1Requested = False
        print('5678_1')
        if (irq1WasRequested and self.kbdClockEnabled and self.allowIrq1):
            print('5678_2')
            self.main.platform.pic.raiseIrq(KBC_IRQ)
            print('5678_3')
    cpdef appendToCtrlBytes(self, bytes data):
        self.ctrlBuffer += data
    cpdef appendToOutBytes(self, bytes data):
        self.outBuffer += data
    cpdef appendToOutBytesImm(self, bytes data):
        self.appendToOutBytes(data)
        ##self.main.platform.pic.lowerIrq(KBC_IRQ)
        if (self.allowIrq1): # and self.kbdClockEnabled):
            self.irq1Requested = True
            ###self.doKbcIrq()
    cpdef appendToOutBytesDoIrq(self, bytes data):
        self.appendToCtrlBytes(data)
        ###self.processCtrlToOut()
    cpdef appendToInBytes(self, bytes data):
        self.inBuffer += data
    cpdef processCtrlToOut(self):
        cdef unsigned short ctrlBufferLen
        ctrlBufferLen = len(self.ctrlBuffer)
        if (ctrlBufferLen):
            self.appendToOutBytes(self.ctrlBuffer)
            self.ctrlBuffer = bytes()
        elif (self.allowIrq1 and self.kbdClockEnabled):
            self.irq1Requested = True
    cpdef setKeyboardRepeatRate(self, unsigned char data): # input is data from cmd 0xf3
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
        if (self.main.platform.vga.ui):
            self.main.platform.vga.ui.setRepeatRate(delay, interval)
    cpdef keySend(self, unsigned char keyId, unsigned char keyUp):
        cdef unsigned char escaped
        cdef bytes scancode
        if ((not self.kbdClockEnabled) or (not self.scanningEnabled) or (keyId == 0xff)):
            return
        scancode = SCANCODES[keyId][self.currentScancodesSet][keyUp]
        if (self.translateScancodes):
            escaped = 0x00
            for sc in scancode:
                if (sc == 0xf0):
                    escaped = 0x80
                else:
                    self.appendToOutBytes( bytes([( TRANSLATION_8042[sc] | escaped )]) )
                    escaped = 0x00
        else:
            self.appendToOutBytes(scancode)
        if (self.allowIrq1 and self.kbdClockEnabled):
            self.irq1Requested = True
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char retByte = 0
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x64):
                return ((0x10) | \
                       (self.lastUsedPort << 3) | \
                       (self.sysf << 2) | \
                       ((len(self.inBuffer)!=0)<<1) | \
                       ( (len(self.ctrlBuffer)!=0) or (len(self.outBuffer)!=0)))
            elif (ioPortAddr == 0x60):
                self.irq1Requested = False
                self.main.platform.pic.lowerIrq(KBC_IRQ)
                ###self.processCtrlToOut()
                if (len(self.ctrlBuffer) >= 1):
                    retByte = self.ctrlBuffer[0]
                    ###if (self.allowIrq1 and self.kbdClockEnabled):
                    ###    self.irq1Requested = True
                    if (len(self.ctrlBuffer) >= 2):
                        self.ctrlBuffer = self.ctrlBuffer[1:]
                    else:
                        self.ctrlBuffer = bytes()
                elif (len(self.outBuffer) >= 1):
                    retByte = self.outBuffer[0]
                    if (self.allowIrq1 and self.kbdClockEnabled):
                        self.irq1Requested = True
                    if (len(self.outBuffer) >= 2):
                        self.outBuffer = self.outBuffer[1:]
                    else:
                        self.outBuffer = bytes()
                ##if (self.irq1Requested and self.allowIrq1 and self.kbdClockEnabled):
                ##    self.doKbcIrq()
                return retByte
            elif (ioPortAddr == 0x61):
                return (self.ppcbT2Both and PPCB_T2BOTH) | \
                       (self.ppcbT2Out and PPCB_T2OUT)
            elif (ioPortAddr == 0x92):
                return (self.main.cpu.getA20State() << 1)
            else:
                self.main.printMsg("inPort: port {0:#04x} is not supported.", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cpdef outPort(self, unsigned short ioPortAddr, unsigned char data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x60):
                if (self.needWriteBytes == 0):
                    self.lastKbcCmdByte, self.lastKbCmdByte = 0, data
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
                        self.appendToOutBytes(b'\xfa\xaa')
                    elif (data in (0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd)):
                        self.appendToOutBytes(b'\xfe')
                    else:
                        self.main.printMsg("outPort: data {0:#04x} is not supported. (port {1:#04x})", data, ioPortAddr)
                else:
                    if (self.lastKbcCmdByte == 0xd1): # port 0x64
                        self.main.cpu.setA20State( (data & PS2_A20) != 0 )
                        if (not (data & PS2_CPU_RESET)):
                            self.main.cpu.reset()
                    elif (self.lastKbcCmdByte == 0x60): # port 0x64
                        self.translateScancodes = (data >> 6)&1
                        self.kbdClockEnabled = not ((data >> 4)&1)
                        self.sysf = (data >> 2)&1
                        self.allowIrq1 = data&1
                        if (self.allowIrq1 and (not len(self.ctrlBuffer) and len(self.outBuffer))):
                            self.irq1Requested = True
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
                    ##self.main.platform.pic.lowerIrq(KBC_IRQ)
                    ##if (len(self.outBuffer) and self.irq1Requested and self.kbdClockEnabled and self.allowIrq1):
                    ##    self.doKbcIrq()
            elif (ioPortAddr == 0x64):
                self.lastKbcCmdByte, self.lastKbCmdByte = data, 0
                if (data == 0x20): # read keyboard mode
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
                    self.ctrlBuffer = bytes()
                    self.outBuffer = bytes()
                    self.sysf = True
                    self.appendToOutBytesDoIrq(b'\x55')
                elif (data == 0xab):
                    self.appendToOutBytesDoIrq(b'\x00')
                elif (data == 0xad): # disable keyboard
                    self.kbdClockEnabled = False
                elif (data == 0xae): # enable keyboard
                    self.kbdClockEnabled = True
                elif (data == 0xd0):
                    outputByte = ((self.irq1Requested << 4) | (self.main.cpu.getA20State() << 1) | 0x01)
                    self.appendToOutBytesDoIrq(bytes([outputByte]))
                elif (data == 0xd1):
                    self.needWriteBytes = 1
                elif (data == 0xdd):
                    self.main.cpu.setA20State( False )
                elif (data == 0xdf):
                    self.main.cpu.setA20State( True )
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
                self.main.cpu.setA20State( (data & PS2_A20) != 0 )
            else:
                self.main.printMsg("outPort: port {0:#04x} is not supported. (data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cpdef timerFunc(self):
        while (not self.main.quitEmu):
            if (((not len(self.ctrlBuffer)) and len(self.outBuffer)) and self.allowIrq1 and self.kbdClockEnabled and self.irq1Requested):
                print('9876_1')
                self.doKbcIrq()
            self.irq1Requested = False
            time.sleep(0.20)
    cpdef initThread(self):
        self.main.misc.createThread(self.timerFunc, True)
    cpdef run(self):
        self.initDevice()
        self.initThread()
        self.main.platform.addHandlers((0x60, 0x61, 0x64, 0x92), self)


