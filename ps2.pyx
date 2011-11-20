
include "globals.pxi"

PPCB_T2BOTH = 3
PPCB_T2OUT = 0x20

PS2_CPU_RESET = 1
PS2_A20 = 2
PS2_IRQ = 0x01

cdef class PS2:
    cpdef object main, outBuffer, inBuffer
    cdef public unsigned char ppcbT2Both, ppcbT2Out, keyboardDisabled
    cdef unsigned char lastUsedPort, needWriteBytes, commandByte, lastKbcCmdByte, lastKbCmdByte
    def __init__(self, object main):
        self.main = main
    cpdef reset(self):
        self.outBuffer = bytearray() # KBC -> CPU
        self.inBuffer  = bytearray() # CPU -> KBC
        self.lastUsedPort = False # 0==0x60; 1==(0x61 or 0x64)
        self.ppcbT2Both = False
        self.ppcbT2Out = False
        self.keyboardDisabled = False
        self.needWriteBytes = 0 # need to write $N bytes to 0x60
        self.commandByte = 0
        self.lastKbcCmdByte = 0
        self.lastKbCmdByte = 0
    cpdef appendToOutBytes(self, object data):
        self.outBuffer += data
    cpdef appendToInBytes(self, object data):
        self.inBuffer += data
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
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char retByte = 0
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x64):
                #return 0x14                    #### 4==1<<2
                return (self.lastUsedPort << 3) | \
                       (4) | \
                       ((len(self.inBuffer)!=0)<<1) | \
                       (len(self.outBuffer)!=0)
            elif (ioPortAddr == 0x60):
                if (len(self.outBuffer) >= 1):
                    retByte = self.outBuffer[0]
                if (len(self.outBuffer) >= 2):
                    self.outBuffer = self.outBuffer[1:]
                else:
                    self.outBuffer = bytes()
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
                    if (data == 0xee):
                        self.appendToOutBytes(bytearray(b'\xee'))
                    elif (data == 0xf3): # set repeat rate
                        self.needWriteBytes = 1
                    elif (data == 0xf4):
                        self.appendToOutBytes(bytearray(b'\xfa'))
                    elif (data == 0xf5):
                        self.appendToOutBytes(bytearray(b'\xfa'))
                    elif (data == 0xf6): # load default
                        pass
                    elif (data == 0xfe): # reset cpu
                        self.main.cpu.reset()
                    elif (data == 0xff):
                        self.appendToOutBytes(bytearray(b'\xfa\xaa'))
                    else:
                        self.main.printMsg("outPort: data {0:#04x} is not supported. (port {1:#04x})", data, ioPortAddr)
                else:
                    if (self.lastKbcCmdByte == 0xd1): # port 0x64
                        ##if ((data & PS2_CPU_RESET) != 0): # TODO: TO..
                        ##    self.main.cpu.reset() # ..DO
                        self.main.cpu.setA20State( (data & PS2_A20) != 0 )
                    elif (self.lastKbcCmdByte == 0x60): # port 0x64
                        self.commandByte = data
                    elif (self.lastKbCmdByte == 0xf3): # port 0x60
                        pass
                    else:
                        self.main.printMsg("outPort: data {0:#04x} is not supported. (port {1:#04x}, needWriteBytes=={2:d}, lastKbcCmdByte=={3:#04x}, lastKbCmdByte=={4:#04x})", data, ioPortAddr, self.needWriteBytes, self.lastKbcCmdByte, self.lastKbCmdByte)
                    self.needWriteBytes -= 1
                    
            elif (ioPortAddr == 0x64):
                self.lastKbcCmdByte, self.lastKbCmdByte = data, 0
                if (data == 0x20): # read keyboard mode
                    self.appendToOutBytes(bytes([self.commandByte]))
                elif (data == 0x60): # write keyboard mode
                    self.needWriteBytes = 1
                elif (data == 0xa8): # activate mouse
                    pass
                elif (data == 0xae): # activate keyboard
                    pass
                elif (data == 0xaa):
                    self.appendToOutBytes(b'\x55')
                elif (data == 0xab):
                    self.appendToOutBytes(b'\x00')
                elif (data == 0xad): # disable keyboard
                    self.keyboardDisabled = True
                elif (data == 0xae): # enable keyboard
                    self.keyboardDisabled = False
                elif (data == 0xd0):
                    outputByte = (self.main.cpu.getA20State() << 1)
                    self.appendToOutBytes(bytes([outputByte]))
                elif (data == 0xd1):
                    self.needWriteBytes = 1
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
    cpdef run(self):
        self.reset()
        self.main.platform.addHandlers((0x60, 0x61, 0x64, 0x92), self)


