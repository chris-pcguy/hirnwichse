
include "globals.pxi"


DEF ATA1_BASE = 0x1f0
DEF ATA2_BASE = 0x170
DEF ATA3_BASE = 0x1e8
DEF ATA4_BASE = 0x168

DEF ATA1_IRQ = 14
DEF ATA2_IRQ = 15

DEF SELECT_SLAVE_DRIVE = 0x10
DEF USE_LBA = 0x40
DEF USE_LBA28 = 0xa0
DEF CONTROL_REG_SKC = 0x10
DEF CONTROL_REG_SHOULD_BE_SET = 0x8 # according to bochs' rombios, this should ALWAYS be set.
DEF CONTROL_REG_SRST = 0x4
DEF CONTROL_REG_NIEN = 0x2

cdef class AtaDrive:
    def __init__(self, AtaChannel ataChannel, object main, unsigned char driveId):
        self.ataChannel = ataChannel
        self.main = main
        self.driveId = driveId
        self.isPresent = False
    cdef void reset(self):
        self.sector = self.sectorCount = 1
        self.sectorCountFlipFlop = self.sectorHighFlipFlop = self.sectorMiddleFlipFlop = self.sectorLowFlipFlop = False
    cdef void run(self):
        pass


cdef class AtaChannel:
    def __init__(self, Ata ata, object main, unsigned char channelId):
        self.ata = ata
        self.main = main
        self.channelId = channelId
        if (self.channelId == 0):
            self.irq = ATA1_IRQ
        elif (self.channelId == 1):
            self.irq = ATA2_IRQ
        else:
            self.irq = None
        self.driveId = 0
        self.drives = (AtaDrive(self, self.main, 0), AtaDrive(self, self.main, 1))
    cdef void reset(self, unsigned char swReset):
        cdef AtaDrive drive
        self.drq = self.err = self.useLBA = self.useLBA48 = False
        self.seekComplete = self.irqEnabled = True
        if (self.irq):
            (<Pic>self.main.platform.pic).lowerIrq(self.irq)
        if (not swReset):
            self.driveId = 0
            self.doReset = self.driveBusy = self.resetInProgress = False
            self.driveReady = True
        else:
            self.driveReady = False
            self.driveBusy = self.resetInProgress = True
        for drive in self.drives:
            drive.reset()
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef AtaDrive drive
        cdef unsigned char ret = BITMASK_BYTE
        drive = self.drives[self.driveId]
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x2):
                if (not drive.sectorCountFlipFlop and self.useLBA and self.useLBA48):
                    ret = (drive.sectorCount>>8)&0xff
                else:
                    ret = drive.sectorCount&0xff
                drive.sectorCountFlipFlop = not drive.sectorCountFlipFlop
            elif (ioPortAddr == 0x3):
                if (not drive.sectorLowFlipFlop and self.useLBA and self.useLBA48):
                    ret = (drive.sector>>24)&0xff
                else:
                    ret = drive.sector&0xff
                drive.sectorLowFlipFlop = not drive.sectorLowFlipFlop
            elif (ioPortAddr == 0x4):
                if (not drive.sectorMiddleFlipFlop and self.useLBA and self.useLBA48):
                    ret = (drive.sector>>32)&0xff
                else:
                    ret = (drive.sector>>8)&0xff
                drive.sectorMiddleFlipFlop = not drive.sectorMiddleFlipFlop
            elif (ioPortAddr == 0x5):
                if (not drive.sectorHighFlipFlop and self.useLBA and self.useLBA48):
                    ret = (drive.sector>>40)&0xff
                else:
                    ret = (drive.sector>>16)&0xff
                drive.sectorHighFlipFlop = not drive.sectorHighFlipFlop
            elif (ioPortAddr == 0x6):
                ret = (0xa0) | (self.useLBA << 6) | (self.driveId << 4) # | (self.headNo&0xf)
            elif (ioPortAddr == 0x7 or ioPortAddr == 0x1fe or ioPortAddr == 0x206):
                if (not drive.isPresent):
                    ret = 0x00
                else:
                    ret = (self.driveBusy << 7) | (self.driveReady << 6) | (self.seekComplete << 4) | (self.drq << 3) | \
                        (self.err)
                    if (self.irq):
                        (<Pic>self.main.platform.pic).lowerIrq(self.irq)
            else:
                self.main.notice("AtaChannel::inPort: channelId: {0:d}; ioPortAddr: {1:#06x}; dataSize: {2:d}", self.channelId, ioPortAddr, dataSize)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef AtaDrive drive
        cdef unsigned char prevReset
        drive = self.drives[self.driveId]
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x1):
                pass # ignored
            elif (ioPortAddr == 0x2):
                if (not drive.sectorCountFlipFlop and self.useLBA and self.useLBA48):
                    drive.sectorCount = (drive.sectorCount&0x00ff)|((data&0xff)<<8)
                else:
                    drive.sectorCount = (drive.sectorCount&0xff00)|(data&0xff)
                drive.sectorCountFlipFlop = not drive.sectorCountFlipFlop
            elif (ioPortAddr == 0x3):
                if (not drive.sectorLowFlipFlop and self.useLBA and self.useLBA48):
                    drive.sector = (drive.sector&0xffff00ffffff)|((data&0xff)<<24)
                else:
                    drive.sector = (drive.sector&0xffffffffff00)|(data&0xff)
                drive.sectorLowFlipFlop = not drive.sectorLowFlipFlop
            elif (ioPortAddr == 0x4):
                if (not drive.sectorMiddleFlipFlop and self.useLBA and self.useLBA48):
                    drive.sector = (drive.sector&0xff00ffffffff)|(<unsigned long int>(data&0xff)<<32)
                else:
                    drive.sector = (drive.sector&0xffffffff00ff)|((data&0xff)<<8)
                drive.sectorMiddleFlipFlop = not drive.sectorMiddleFlipFlop
            elif (ioPortAddr == 0x5):
                if (not drive.sectorHighFlipFlop and self.useLBA and self.useLBA48):
                    drive.sector = (drive.sector&0x00ffffffffff)|(<unsigned long int>(data&0xff)<<40)
                else:
                    drive.sector = (drive.sector&0xffffff00ffff)|((data&0xff)<<16)
                drive.sectorHighFlipFlop = not drive.sectorHighFlipFlop
            elif (ioPortAddr == 0x6):
                self.driveId = 1 if ((data & SELECT_SLAVE_DRIVE) != 0) else 0
                drive = self.drives[self.driveId]
                drive.sector = (drive.sector&0xfffff0ffffff)|((data&0xf)<<24)
                self.useLBA = True if ((data & USE_LBA) != 0) else False
                self.useLBA48 = True if ((data & USE_LBA28) != USE_LBA28) else False
            elif (ioPortAddr == 0x1fe or ioPortAddr == 0x206):
                if (not (data & CONTROL_REG_SHOULD_BE_SET)):
                    self.main.exitError("outPort: CONTROL_REG_SHOULD_BE_SET should be set! (obvious message is obvious.)")
                prevReset = self.doReset
                self.irqEnabled = True if ((data & CONTROL_REG_NIEN) != CONTROL_REG_NIEN) else False
                self.doReset = True if ((data & CONTROL_REG_SRST) == CONTROL_REG_SRST) else False
                if (not prevReset and self.doReset):
                    self.reset(True)
                elif (self.resetInProgress and not self.doReset):
                    self.driveBusy = self.resetInProgress = False
                    self.driveReady = True
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
        #self.channels = (AtaChannel(self, self.main, 0), AtaChannel(self, self.main, 1), AtaChannel(self, self.main, 2), AtaChannel(self, self.main, 3))
        self.channels = (AtaChannel(self, self.main, 0), AtaChannel(self, self.main, 1))
    cdef void reset(self):
        cdef AtaChannel channel
        for channel in self.channels:
            channel.reset(False)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (ioPortAddr in ATA1_PORTS and len(self.channels) >= 1 and self.channels[0]):
            return (<AtaChannel>self.channels[0]).inPort(ioPortAddr-ATA1_BASE, dataSize)
        elif (ioPortAddr in ATA2_PORTS and len(self.channels) >= 2 and self.channels[1]):
            return (<AtaChannel>self.channels[1]).inPort(ioPortAddr-ATA2_BASE, dataSize)
        elif (ioPortAddr in ATA3_PORTS and len(self.channels) >= 3 and self.channels[2]):
            return (<AtaChannel>self.channels[2]).inPort(ioPortAddr-ATA3_BASE, dataSize)
        elif (ioPortAddr in ATA4_PORTS and len(self.channels) >= 4 and self.channels[3]):
            return (<AtaChannel>self.channels[3]).inPort(ioPortAddr-ATA4_BASE, dataSize)
        return BITMASK_BYTE
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (ioPortAddr in ATA1_PORTS and len(self.channels) >= 1 and self.channels[0]):
            (<AtaChannel>self.channels[0]).outPort(ioPortAddr-ATA1_BASE, data, dataSize)
        elif (ioPortAddr in ATA2_PORTS and len(self.channels) >= 2 and self.channels[1]):
            (<AtaChannel>self.channels[1]).outPort(ioPortAddr-ATA2_BASE, data, dataSize)
        elif (ioPortAddr in ATA3_PORTS and len(self.channels) >= 3 and self.channels[2]):
            (<AtaChannel>self.channels[2]).outPort(ioPortAddr-ATA3_BASE, data, dataSize)
        elif (ioPortAddr in ATA4_PORTS and len(self.channels) >= 4 and self.channels[3]):
            (<AtaChannel>self.channels[3]).outPort(ioPortAddr-ATA4_BASE, data, dataSize)
    cdef void run(self):
        pass


