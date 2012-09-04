
include "globals.pxi"


cdef class AtaChannel:
    def __init__(self, Ata ata, object main, unsigned char channelId):
        self.ata = ata
        self.main = main
        self.channelId = channelId
    cdef void reset(self):
        pass
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            self.main.notice("AtaChannel::inPort: channelId: {0:d}; ioPortAddr: {1:#06x}; dataSize: {2:d}", self.channelId, ioPortAddr, dataSize)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return BITMASK_BYTE
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            self.main.notice("AtaChannel::outPort: channelId: {0:d}; ioPortAddr: {1:#06x}; data: {2:#04x}; dataSize: {3:d}", self.channelId, ioPortAddr, data, dataSize)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cdef void run(self):
        pass


cdef class Ata:
    def __init__(self, object main):
        self.main = main
        self.channels = (AtaChannel(self, self.main, 0), AtaChannel(self, self.main, 1), AtaChannel(self, self.main, 2), AtaChannel(self, self.main, 3))
    cdef void reset(self):
        pass
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (ioPortAddr in ATA1_PORTS):
            return (<AtaChannel>self.channels[0]).inPort(ioPortAddr, dataSize)
        elif (ioPortAddr in ATA2_PORTS):
            return (<AtaChannel>self.channels[1]).inPort(ioPortAddr, dataSize)
        elif (ioPortAddr in ATA3_PORTS):
            return (<AtaChannel>self.channels[2]).inPort(ioPortAddr, dataSize)
        elif (ioPortAddr in ATA4_PORTS):
            return (<AtaChannel>self.channels[3]).inPort(ioPortAddr, dataSize)
        return BITMASK_BYTE
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (ioPortAddr in ATA1_PORTS):
            (<AtaChannel>self.channels[0]).outPort(ioPortAddr, data, dataSize)
        elif (ioPortAddr in ATA2_PORTS):
            (<AtaChannel>self.channels[1]).outPort(ioPortAddr, data, dataSize)
        elif (ioPortAddr in ATA3_PORTS):
            (<AtaChannel>self.channels[2]).outPort(ioPortAddr, data, dataSize)
        elif (ioPortAddr in ATA4_PORTS):
            (<AtaChannel>self.channels[3]).outPort(ioPortAddr, data, dataSize)
    cdef void run(self):
        pass


