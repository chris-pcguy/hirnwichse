import misc, sys

class Vga:
    def __init__(self, main):
        self.main = main
    def inPort(self, ioPortAddr, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            pass
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, ioPortAddr, data, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr == 0x400): # Bochs' Panic Port
                print('Panic port: byte=={0:#04x}'.format(data))
            elif (ioPortAddr == 0x401): # Bochs' Panic Port2
                print('Panic port2: byte=={0:#04x}'.format(data))
            elif (ioPortAddr == 0x402): # Bochs' Info Port
                print('Info port: byte=={0:#04x}'.format(data))
            elif (ioPortAddr == 0x403): # Bochs' Debug Port
                print('Debug port: byte=={0:#04x}'.format(data))
            
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers((0x400, 0x401, 0x402, 0x403), self.inPort)
        self.main.platform.addWriteHandlers((0x400, 0x401, 0x402, 0x403), self.outPort)


