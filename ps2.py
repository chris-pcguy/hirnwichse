import misc


PPCB_T2GATE = 1
PPCB_SPKR = 2
PPCB_T2OUT = 0x20



class PS2:
    def __init__(self, main):
        self.main = main
        self.outBuffer = bytearray() # KBC -> CPU
        self.inBuffer  = bytearray() # CPU -> KBC
        self.lastUsedPort = False # 0==0x60; 1==(0x61 or 0x64)
        self.ppcbT2Gate = False
        self.ppcbSpkr = False
        self.ppcbT2Out = False
    def appendToOut(self, data):
        if (isinstance(data, int)):
            self.outBuffer += bytearray([data])
            return
        self.outBuffer += bytearray(list(data))
    def appendToIn(self, data):
        if (isinstance(data, int)):
            self.inBuffer += bytearray([data])
            return
        self.inBuffer += bytearray(list(data))
    def inPort(self, ioPortAddr, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
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
            else:
                self.main.printMsg("inPort: port {0:#04x} is not supported.)", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, ioPortAddr, data, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr == 0x60):
                if (data == 0xfe):
                    self.main.cpu.reset()
                elif (data == 0xee):
                    self.appendToOut(0xee)
                elif (data == 0xf4):
                    self.appendToOut(0xfa)
                elif (data == 0xf5):
                    self.appendToOut(0xfa)
                elif (data == 0xff):
                    self.appendToOut(b'\xfa\xaa')
                else:
                    self.main.printMsg("outPort: data {0:#04x} is not supported. (port {1:#04x})", data, ioPortAddr)
            elif (ioPortAddr == 0x64):
                if (data == 0x60): # write keyboard mode
                    pass
                elif (data == 0xa8): # activate mouse
                    pass
                elif (data == 0xae): # activate keyboard
                    pass
                elif (data == 0xaa):
                    self.appendToOut(0x55)
                elif (data == 0xab):
                    self.appendToOut(0x00)
                else:
                    self.main.printMsg("outPort: data {0:#04x} is not supported. (port {1:#04x})", data, ioPortAddr)
            elif (ioPortAddr == 0x61):
                self.ppcbT2Gate = (data&PPCB_T2GATE)!=0
                self.ppcbSpkr = (data&PPCB_SPKR)!=0
                self.ppcbT2Out = (data&PPCB_T2OUT)!=0
                
            else:
                self.main.printMsg("outPort: port {0:#04x} is not supported. (data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers((0x60, 0x61, 0x64, 0x92), self.inPort)
        self.main.platform.addWriteHandlers((0x60, 0x61, 0x64, 0x92), self.outPort)


