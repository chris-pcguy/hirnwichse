
class Pic:
    def __init__(self, main):
        self.main = main
    def inPort(self, long ioPortAddr, int dataSize):
        if (dataSize == 8):
            pass
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, long ioPortAddr, data, int dataSize):
        if (dataSize == 8):
            pass
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        pass


