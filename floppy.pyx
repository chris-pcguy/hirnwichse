import misc

cdef class Floppy:
    cdef public object main
    cdef tuple readPorts, writePorts
    def __init__(self, object main):
        self.main = main
        self.readPorts = (0x3f0, 0x3f1, 0x3f3, 0x3f4, 0x3f5, 0x3f6, 0x3f7)
        self.writePorts = (0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f6, 0x3f7)
    def inPort(self, short ioPortAddr, unsigned char dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            if (ioPortAddr == 0x3f6):
                self.main.printMsg("inPort: reserved read from port {0:#06x}. (dataSize byte)", ioPortAddr)
            else:
                self.main.printMsg("inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, short ioPortAddr, short data, unsigned char dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            if (ioPortAddr == 0x3f6):
                self.main.printMsg("outPort: reserved write to port {0:#06x}. (dataSize byte, data {1:#04x})", ioPortAddr, data)
            else:
                self.main.printMsg("outPort: port {0:#06x} not supported. (dataSize byte, data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers(self.readPorts, self.inPort)
        self.main.platform.addWriteHandlers(self.writePorts, self.outPort)


