
include "globals.pxi"


cdef class AtaDrive:
    def __init__(self, AtaChannel ataChannel, object main, unsigned char driveId):
        self.ataChannel = ataChannel
        self.main = main
        self.driveId = driveId
    cdef void reset(self):
        pass
    cdef void run(self):
        pass


cdef class AtaChannel:
    def __init__(self, Ata ata, object main, unsigned char channelId):
        self.ata = ata
        self.main = main
        self.channelId = channelId
        self.drives = (AtaDrive(self, self.main, 0), AtaDrive(self, self.main, 1))
    cdef void reset(self):
        cdef AtaDrive drive
        for drive in self.drives:
            drive.reset()
        self.driveId = 0
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            self.main.notice("AtaChannel::inPort: channelId: {0:d}; ioPortAddr: {1:#06x}; dataSize: {2:d}", self.channelId, ioPortAddr, dataSize)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return BITMASK_BYTE
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x1):
                pass # ignored
            elif (ioPortAddr == 0x6):
                if (data == 0xa0):
                    self.driveId = 0
                elif (data == 0xb0):
                    self.driveId = 1
                else:
                    self.main.notice("AtaChannel::outPort: which drive should be selected. (channelId: {0:d}; ioPortAddr: {1:#06x}; data: {2:#04x}; dataSize: {3:d})", self.channelId, ioPortAddr, data, dataSize)
            else:
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
        cdef AtaChannel channel
        for channel in self.channels:
            channel.reset()
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (ioPortAddr in ATA1_PORTS):
            return (<AtaChannel>self.channels[0]).inPort(ioPortAddr-ATA1_BASE, dataSize)
        elif (ioPortAddr in ATA2_PORTS):
            return (<AtaChannel>self.channels[1]).inPort(ioPortAddr-ATA2_BASE, dataSize)
        elif (ioPortAddr in ATA3_PORTS):
            return (<AtaChannel>self.channels[2]).inPort(ioPortAddr-ATA3_BASE, dataSize)
        elif (ioPortAddr in ATA4_PORTS):
            return (<AtaChannel>self.channels[3]).inPort(ioPortAddr-ATA4_BASE, dataSize)
        return BITMASK_BYTE
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (ioPortAddr in ATA1_PORTS):
            (<AtaChannel>self.channels[0]).outPort(ioPortAddr-ATA1_BASE, data, dataSize)
        elif (ioPortAddr in ATA2_PORTS):
            (<AtaChannel>self.channels[1]).outPort(ioPortAddr-ATA2_BASE, data, dataSize)
        elif (ioPortAddr in ATA3_PORTS):
            (<AtaChannel>self.channels[2]).outPort(ioPortAddr-ATA3_BASE, data, dataSize)
        elif (ioPortAddr in ATA4_PORTS):
            (<AtaChannel>self.channels[3]).outPort(ioPortAddr-ATA4_BASE, data, dataSize)
    cdef void run(self):
        pass


