
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"

from time import sleep
from atexit import register
from os import remove
from os.path import exists
import socket, serial

cdef class SerialPort:
    def __init__(self, Serial serial, unsigned char serialIndex):
        self.serial = serial
        self.main = self.serial.main
        self.serialIndex = serialIndex
        if (not self.serialIndex):
            self.serialFilename = self.main.serial1Filename
            self.irq = 4
        else:
            self.serialFilename = self.main.serial2Filename
            self.irq = 3
        self.sock = self.fp = None
        self.dlab = self.isDev = False
        self.dataBits = 3
        self.stopBits = 0
        self.parity = 0
        self.divisor = 1 # 12
        self.interruptEnableRegister = self.interruptIdentificationFifoControl = self.modemControlRegister = self.modemStatusRegister = self.scratchRegister = 0
        self.lineStatusRegister = 0x20
        self.data = bytes()
        if (len(self.serialFilename)):
            if (self.serialFilename.startswith(b"socket:")):
                self.serialFilename = self.serialFilename[7:]
                if (exists(self.serialFilename)):
                    remove(self.serialFilename)
                self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                self.sock.bind(self.serialFilename)
                self.sock.listen(1)
                self.fp, addr = self.sock.accept()
            elif (self.serialFilename.startswith(b"serial:")):
                self.serialFilename = self.serialFilename[7:]
                self.isDev = True
                if (exists(self.serialFilename)):
                    self.fp = serial.Serial(port=self.serialFilename)
                    self.setBits()
            elif (exists(self.serialFilename)):
                self.fp = open(self.serialFilename, "w+b")
    cdef void reset(self):
        pass
    cpdef setBits(self):
        cdef unsigned char tempVal
        self.fp.baudrate = 115200//self.divisor
        if (self.parity & 1):
            tempVal = self.parity >> 1
            if (not tempVal):
                self.fp.parity = serial.PARITY_ODD
            elif (tempVal == 1):
                self.fp.parity = serial.PARITY_EVEN
            elif (tempVal == 2):
                self.fp.parity = serial.PARITY_MARK
            elif (tempVal == 3):
                self.fp.parity = serial.PARITY_SPACE
        else:
            self.fp.parity = serial.PARITY_NONE
        if (self.stopBits & 1):
            if (self.dataBits): # dataBits != FIVEBITS
                self.fp.stopbits = serial.STOPBITS_TWO
            else:
                self.fp.stopbits = serial.STOPBITS_ONE_POINT_FIVE
        else:
            self.fp.stopbits = serial.STOPBITS_ONE
        self.fp.bytesize = 5+self.dataBits
    cpdef handleIrqs(self):
        if (self.fp is None):
            return
        while (not self.main.quitEmu):
            self.readData()
            self.writeData(bytes())
            sleep(1)
    cpdef quitFunc(self):
        if (self.sock is not None):
            self.sock.close()
            if (exists(self.serialFilename)):
                remove(self.serialFilename)
    cdef void raiseIrq(self):
        if (self.modemControlRegister & 0x8):
            self.main.notice("SerialPort::raiseIrq: raiseIrq enabled (self.serialIndex {0:d})", self.serialIndex)
            (<Pic>self.main.platform.pic).lowerIrq(self.irq)
            (<Pic>self.main.platform.pic).raiseIrq(self.irq)
        else:
            self.main.notice("SerialPort::raiseIrq: raiseIrq disabled (self.serialIndex {0:d})", self.serialIndex)
    cdef void readData(self):
        cdef bytes tempData
        if (self.fp is not None):
            if (not self.modemControlRegister & 0x10):
                if (self.sock is not None):
                    try:
                        tempData = self.fp.recv(1, socket.MSG_DONTWAIT | socket.MSG_PEEK)
                        if (len(tempData) > 0):
                            self.data += self.fp.recv(1)
                    except BlockingIOError:
                        pass
                else:
                    self.data += self.fp.read(1)
            #usleep(100000)
            #usleep(round(1.0e6/(115200.0/self.divisor)))
            if ((self.interruptEnableRegister & 0x1) and len(self.data) > 0):
                self.raiseIrq()
    cdef void writeData(self, bytes data):
        cdef unsigned int retlen
        if (self.fp is not None):
            if (len(data) > 0):
                self.lineStatusRegister &= ~0x20
                self.main.notice("SerialPort{0:d}::writeData: write string: {1:s}", self.serialIndex, data.decode())
                if (self.modemControlRegister & 0x10):
                    self.data += data
                else:
                    if (self.sock is not None):
                        retlen = self.fp.send(data)
                    else:
                        retlen = self.fp.write(data)
                        self.fp.flush()
                #usleep(100000)
                #usleep(round(1.0e6/(115200.0/self.divisor)))
                if (retlen <= len(data)):
                    self.lineStatusRegister |= 0x20
                #if (1):
                #self.lineStatusRegister |= 0x20
                if (self.interruptEnableRegister & 0x2):
                    self.raiseIrq()
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char ret = BITMASK_BYTE
        cdef bytes tempData
        if (self.fp is None):
            return ret
        elif (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0):
                if (self.dlab): # low byte divisor
                    return (self.divisor & BITMASK_BYTE)
                else:
                    if (not len(self.data)):
                        self.readData()
                    if (len(self.data) > 0):
                        ret = self.data[0]
                        self.main.notice("SerialPort{0:d}::inPort: read character: {1:s}", self.serialIndex, chr(ret))
                        if (len(self.data) > 1):
                            self.data = self.data[1:]
                        else:
                            self.data = bytes()
                    #else:
                    #    ret = 0
            elif (ioPortAddr == 1):
                if (self.dlab): # high byte divisor
                    return (self.divisor >> 8)
                else:
                    return self.interruptEnableRegister
            elif (ioPortAddr == 2):
                return 0x1
            elif (ioPortAddr == 3):
                return ((self.dlab << 7) | (self.parity << 3) | (self.stopBits << 2) | (self.dataBits))
            elif (ioPortAddr == 4):
                return self.modemControlRegister
            elif (ioPortAddr == 5):
                self.lineStatusRegister &= ~1
                if (self.sock is not None):
                    self.readData()
                    if (len(self.data) > 0):
                        self.lineStatusRegister |= 1
                elif (len(self.data) > 0):
                    self.lineStatusRegister |= 1
                return self.lineStatusRegister
            elif (ioPortAddr == 6):
                return self.modemStatusRegister
            elif (ioPortAddr == 7):
                return self.scratchRegister
            else:
                self.main.exitError("SerialPort::inPort_1: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        else:
            self.main.exitError("SerialPort::inPort_2: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (self.fp is None):
            return
        elif (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0):
                if (self.dlab): # low byte divisor
                    self.main.notice("SerialPort::outPort_3: set divisor low")
                    self.divisor &= 0xff00
                    self.divisor |= data
                    self.setBits()
                else:
                    self.main.notice("SerialPort{0:d}::outPort: write character: {1:s}", self.serialIndex, chr(data))
                    self.writeData(bytes([data]))
            elif (ioPortAddr == 1):
                if (self.dlab): # high byte divisor
                    self.main.notice("SerialPort::outPort_3: set divisor high")
                    self.divisor &= 0x00ff
                    self.divisor |= (data<<8)
                    self.setBits()
                else:
                    self.main.notice("SerialPort::outPort_3: set interruptEnableRegister")
                    self.interruptEnableRegister = data
            elif (ioPortAddr == 2):
                if (data & 1):
                    if (data & 2):
                        self.data = bytes()
                        data &= ~2
                    data &= ~4
                    self.interruptIdentificationFifoControl = data
            elif (ioPortAddr == 3):
                self.dataBits = (data & 3)
                self.stopBits = ((data >> 2) & 1)
                self.parity = ((data >> 3) & 7)
                self.dlab = ((data >> 7) & 1)
                self.setBits()
            elif (ioPortAddr == 4):
                self.modemControlRegister = data
            #elif (ioPortAddr == 5):
            #    self.lineStatusRegister = data
            elif (ioPortAddr == 6):
                self.modemStatusRegister = data
            elif (ioPortAddr == 7):
                self.scratchRegister = data
            else:
                self.main.exitError("SerialPort::outPort_1: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", ioPortAddr, dataSize, data)
        else:
            self.main.exitError("SerialPort::outPort_2: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", ioPortAddr, dataSize, data)
        return
    cdef void run(self):
        if (self.fp is not None):
            self.main.misc.createThread(self.handleIrqs, True)
        if (self.sock is not None):
            register(self.quitFunc)


cdef class Serial:
    def __init__(self, Hirnwichse main):
        self.main = main
        self.ports = (SerialPort(self, 0), SerialPort(self, 1))
    cdef void reset(self):
        cdef SerialPort port
        for port in self.ports:
            port.reset()
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef SerialPort port
        cdef unsigned int ret = BITMASK_BYTE
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in SERIAL1_PORTS):
                port = self.ports[0]
                ret = port.inPort(ioPortAddr-SERIAL1_PORTS[0], dataSize)
            elif (ioPortAddr in SERIAL2_PORTS):
                port = self.ports[1]
                ret = port.inPort(ioPortAddr-SERIAL2_PORTS[0], dataSize)
            else:
                self.main.exitError("Serial::inPort_1: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
                return ret
        else:
            self.main.exitError("Serial::inPort_2: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
            return ret
        self.main.notice("Serial::inPort_3: port {0:#04x} data {1:#04x} dataSize {2:d}.", ioPortAddr, ret, dataSize)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef SerialPort port
        self.main.notice("Serial::outPort_3: port {0:#04x} data {1:#04x} dataSize {2:d}.", ioPortAddr, data, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in SERIAL1_PORTS):
                port = self.ports[0]
                port.outPort(ioPortAddr-SERIAL1_PORTS[0], data, dataSize)
            elif (ioPortAddr in SERIAL2_PORTS):
                port = self.ports[1]
                port.outPort(ioPortAddr-SERIAL2_PORTS[0], data, dataSize)
            else:
                self.main.exitError("Serial::outPort_1: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", ioPortAddr, dataSize, data)
        else:
            self.main.exitError("Serial::outPort_2: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", ioPortAddr, dataSize, data)
        return
    cdef void run(self):
        cdef SerialPort port
        for port in self.ports:
            port.run()


