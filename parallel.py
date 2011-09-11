import misc

class Parallel:
    def __init__(self, main):
        self.main = main
        self.ports = (0x3bc, 0x3bd, 0x3be, 0x378, 0x379, 0x37a, 0x278, 0x279, 0x27a, 0x2bc, 0x2bd, 0x2be)
    def inPort(self, ioPortAddr, dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            pass
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, ioPortAddr, data, dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            pass
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers(self.ports, self.inPort)
        self.main.platform.addWriteHandlers(self.ports, self.outPort)


