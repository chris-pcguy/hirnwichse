import misc

class Floppy:
    def __init__(self, main):
        self.main = main
    def inPort(self, ioPortAddr, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr == 0x3f6):
                self.main.printMsg("inPort: reserved read from port {0:#06x}. (dataSize byte)", ioPortAddr)
            else:
                self.main.printMsg("inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, ioPortAddr, data, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr == 0x3f6):
                self.main.printMsg("outPort: reserved write to port {0:#06x}. (dataSize byte, data {1:#04x})", ioPortAddr, data)
            else:
                self.main.printMsg("outPort: port {0:#06x} not supported. (dataSize byte, data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers((0x3f0, 0x3f1, 0x3f3, 0x3f4, 0x3f5, 0x3f6, 0x3f7), self.inPort)
        self.main.platform.addWriteHandlers((0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f6, 0x3f7), self.outPort)


