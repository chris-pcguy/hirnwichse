
CONTROLLER_MASTER = 0
CONTROLLER_SLAVE  = 1

class Channel:
    def __init__(self, controller):
        self.controller = controller
        self.dma = self.controller.dma
        self.main = self.dma.main

class Controller:
    def __init__(self, dma):
        self.dma = dma
        self.main = self.dma.main
        self.channel[4] = (Channel(self), Channel(self), Channel(self), Channel(self))
        self.reset()
    def reset(self):
        self.flipFlop = False

class ISADma:
    def __init__(self, main):
        self.main = main
        self.ioMasterControllerPorts = (0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,
                                      0x0d,0x0f,0x81,0x82,0x83,0x87)
        self.ioSlaveControllerPorts = (0x89,0x8a,0x8b,0x8f,0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,
                                      0xd0,0xd2,0xd4,0xd6,0xd8,0xda,0xde)
        self.controller[2] = (Controller(self), Controller(self))
    def inPortMaster(self, long ioPortAddr, int dataSize):
        if (dataSize == 8):
            pass
        elif (dataSize == 16):
            pass
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPortMaster(self, long ioPortAddr, data, int dataSize):
        if (dataSize == 8):
            if (ioPortAddr == 0x0c):
                self.controller[0].flipFlop = False
        elif (dataSize == 16):
            pass
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def inPortSlave(self, long ioPortAddr, int dataSize):
        if (dataSize == 8):
            pass
        elif (dataSize == 16):
            pass
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPortSlave(self, long ioPortAddr, data, int dataSize):
        if (dataSize == 8):
            if (ioPortAddr == 0xd8):
                self.controller[1].flipFlop = False
        elif (dataSize == 16):
            pass
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers(self.ioMasterControllerPorts, self.inPortMaster)
        self.main.platform.addReadHandlers(self.ioSlaveControllerPorts,  self.inPortSlave)
        self.main.platform.addWriteHandlers(self.ioMasterControllerPorts, self.outPortMaster)
        self.main.platform.addWriteHandlers(self.ioSlaveControllerPorts, self.outPortSlave)


