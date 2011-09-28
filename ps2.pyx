import misc


PPCB_T2GATE = 1
PPCB_SPKR = 2
PPCB_T2OUT = 0x20

PS2_A20 = 2


cdef class PS2:
    cdef object main, outBuffer, inBuffer
    cdef public unsigned char ppcbT2Gate, ppcbT2Out
    cdef unsigned char lastUsedPort, ppcbSpkr, needWriteBytes, commandByte, lastCtrlCmdByte
    def __init__(self, object main):
        self.main = main
        self.outBuffer = bytearray() # KBC -> CPU
        self.inBuffer  = bytearray() # CPU -> KBC
        self.lastUsedPort = False # 0==0x60; 1==(0x61 or 0x64)
        self.ppcbT2Gate = False
        self.ppcbSpkr = False
        self.ppcbT2Out = False
        self.needWriteBytes = 0 # need to write $N bytes to 0x60
        self.commandByte = 0
        self.lastCtrlCmdByte = 0
    def appendToOutBytes(self, object data):
        self.outBuffer += data
    def appendToInBytes(self, object data):
        self.inBuffer += data
    def inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            if (ioPortAddr == 0x64):
                #return 0x14                    #### 4==1<<2
                return (self.lastUsedPort << 3) | \
                       (4) | \
                       ((len(self.inBuffer)!=0)<<1) | \
                       (len(self.outBuffer)!=0)
            elif (ioPortAddr == 0x60):
                retByte = self.outBuffer[0]
                self.outBuffer = self.outBuffer[1:]
                return retByte
            elif (ioPortAddr == 0x61):
                return (self.ppcbT2Gate and PPCB_T2GATE) | \
                       (self.ppcbSpkr and PPCB_SPKR) | \
                       (self.ppcbT2Out and PPCB_T2OUT)
            elif (ioPortAddr == 0x92):
                return (self.main.cpu.getA20State() << 1)
            else:
                self.main.printMsg("inPort: port {0:#04x} is not supported.", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, unsigned short ioPortAddr, unsigned char data, unsigned char dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            if (ioPortAddr == 0x60):
                if (self.needWriteBytes == 0):
                    self.lastCtrlCmdByte = data
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
                    if (self.lastCtrlCmdByte == 0xd1): # port 0x64
                        self.main.cpu.setA20State( (data & PS2_A20) != 0 )
                    elif (self.lastCtrlCmdByte == 0x60): # port 0x64
                        self.commandByte = data
                    elif (self.lastCtrlCmdByte == 0xf3): # port 0x60
                        pass
                    else:
                        self.main.printMsg("outPort: data {0:#04x} is not supported. (port {1:#04x}, needWriteBytes=={2:d}, lastCtrlCmdByte=={3:#04x})", data, ioPortAddr, self.needWriteBytes, self.lastCtrlCmdByte)
                    self.needWriteBytes -= 1
                    
            elif (ioPortAddr == 0x64):
                self.lastCtrlCmdByte = data
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
                elif (data == 0xd0):
                    outputByte = (self.main.cpu.getA20State() << 1)
                    self.appendToOutBytes(bytes([outputByte]))
                elif (data == 0xd1):
                    self.needWriteBytes = 1
                else:
                    self.main.printMsg("outPort: data {0:#04x} is not supported. (port {1:#04x})", data, ioPortAddr)
            elif (ioPortAddr == 0x61):
                self.ppcbT2Gate = (data&PPCB_T2GATE)!=0
                self.ppcbSpkr = (data&PPCB_SPKR)!=0
                self.ppcbT2Out = (data&PPCB_T2OUT)!=0
            elif (ioPortAddr == 0x92):
                self.main.cpu.setA20State( (data & PS2_A20) != 0 )
                    
            else:
                self.main.printMsg("outPort: port {0:#04x} is not supported. (data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers((0x60, 0x61, 0x64, 0x92), self.inPort)
        self.main.platform.addWriteHandlers((0x60, 0x61, 0x64, 0x92), self.outPort)


