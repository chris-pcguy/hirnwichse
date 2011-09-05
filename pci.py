

import misc

class Pci:
    def __init__(self, main):
        self.main = main
        self.ports = (0xcf8, 0xcf9, 0xcfc)
    def inPort(self, ioPortAddr, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            self.main.printMsg("inPort: port {0:#04x} is not supported. (dataSize == byte)", ioPortAddr)
        elif (dataSize == misc.OP_SIZE_16BIT):
            self.main.printMsg("inPort: port {0:#04x} is not supported. (dataSize == word)", ioPortAddr)
        elif (dataSize == misc.OP_SIZE_32BIT):
            self.main.printMsg("inPort: port {0:#04x} is not supported. (dataSize == dword)", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, ioPortAddr, data, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            self.main.printMsg("outPort: port {0:#04x} is not supported. (data == {1:#04x}, dataSize == byte)", ioPortAddr, data)
        elif (dataSize == misc.OP_SIZE_16BIT):
            self.main.printMsg("outPort: port {0:#04x} is not supported. (data == {1:#04x}, dataSize == word)", ioPortAddr, data)
        elif (dataSize == misc.OP_SIZE_32BIT):
            self.main.printMsg("outPort: port {0:#04x} is not supported. (data == {1:#04x}, dataSize == dword)", ioPortAddr, data)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers(self.ports, self.inPort)
        self.main.platform.addWriteHandlers(self.ports, self.outPort)


