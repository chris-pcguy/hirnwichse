
from os import access, F_OK, R_OK, W_OK, SEEK_END
from os.path import getsize


include "globals.pxi"

DEF HEADS = 16
DEF SPT = 63

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

DEF COMMAND_IDENTIFY = 0xec
DEF COMMAND_READ_LBA28 = 0x20
DEF COMMAND_WRITE_LBA28 = 0x30

DEF SECTOR_SIZE = 512
DEF SECTOR_SHIFT = 9

cdef class AtaDrive:
    def __init__(self, AtaController ataController, object main, unsigned char driveId):
        self.ataController = ataController
        self.main = main
        self.driveId = driveId
        self.isLoaded = False
        self.isWriteProtected = True
        self.diskSize = 0
        self.configSpace = ConfigSpace(SECTOR_SIZE, self.main) # Is the device identity data area actually one sector big?
    cdef inline unsigned short readValue(self, unsigned char index):
        return self.configSpace.csReadValueUnsigned(index << 1, OP_SIZE_WORD)
    cdef inline void writeValue(self, unsigned char index, unsigned short value):
        self.configSpace.csWriteValue(index << 1, value, OP_SIZE_WORD)
    cdef void reset(self):
        self.sector = self.sectorCount = 1
        self.sectorCountFlipFlop = self.sectorHighFlipFlop = self.sectorMiddleFlipFlop = self.sectorLowFlipFlop = False
    cdef void loadDrive(self, bytes filename):
        cdef unsigned char cmosDiskType
        cdef unsigned int cylinders
        if (not filename or not access(filename, F_OK | R_OK)):
            self.main.notice("HD{0:d}: loadDrive: file isn't found/accessable. (filename: {1:s})", (self.ataController.controllerId<<1)+self.driveId, filename)
            return
        self.filename = filename
        if (access(filename, F_OK | R_OK | W_OK)):
            self.fp = open(filename, "r+b")
            self.isLoaded = True
            self.isWriteProtected = False
        elif (access(filename, F_OK | R_OK)):
            self.fp = open(filename, "rb")
            self.isLoaded = True
            self.isWriteProtected = True
        else:
            self.main.notice("HD{0:d}: loadDrive: file isn't found/accessable. (filename: {1:s}, access-cmd)", (self.ataController.controllerId<<1)+self.driveId, filename)
            return
        self.fp.seek(0, SEEK_END)
        self.diskSize = self.fp.tell()
        self.fp.seek(0)
        self.writeValue(0, 0x40) # word 0 ; fixed drive
        cylinders = self.diskSize / (HEADS * SPT)
        if (cylinders > 16383):
            cylinders = 16383
        self.writeValue(1, cylinders) # word 1 ; cylinders
        self.writeValue(3, HEADS) # word 3 ; heads
        self.writeValue(4, SPT << SECTOR_SHIFT) # word 4 ; spt * SECTOR_SIZE
        self.writeValue(5, SECTOR_SIZE) # hdd block size
        self.writeValue(6, SPT) # word 6 ; spt
        self.writeValue(20, 2) # type
        self.writeValue(21, SECTOR_SIZE) # increment in hdd block size
        self.writeValue(83, (1<<10)) # supports lba48
        self.configSpace.csWriteValue(100 << 1, self.diskSize>>SECTOR_SHIFT, OP_SIZE_QWORD) # total number of addressable blocks. (diskSize>>SECTOR_SHIFT == diskSize/SECTOR_SIZE)
        if (self.driveId in (0, 1)):
            cmosDiskType = (<Cmos>self.main.platform.cmos).readValue(CMOS_HDD_DRIVE_TYPE, OP_SIZE_BYTE)
            cmosDiskType |= (0xf0 if (self.driveId == 0) else 0x0f)
            (<Cmos>self.main.platform.cmos).writeValue(CMOS_HDD_DRIVE_TYPE, cmosDiskType, OP_SIZE_BYTE)
            (<Cmos>self.main.platform.cmos).writeValue((CMOS_HD0_EXTENDED_DRIVE_TYPE if (self.driveId == 0) else CMOS_HD1_EXTENDED_DRIVE_TYPE), 0x2f, OP_SIZE_BYTE)
    cdef bytes readBytes(self, unsigned int offset, unsigned int size):
        cdef bytes data
        cdef unsigned int oldPos
        oldPos = self.fp.tell()
        self.fp.seek(offset)
        data = self.fp.read(size)
        if (len(data) < size): # floppy image is too short.
            data += b'\x00'*(size-len(data))
        self.fp.seek(oldPos)
        return data
    cdef bytes readSectors(self, unsigned int sector, unsigned int count): # count in sectors
        return self.readBytes(sector<<SECTOR_SHIFT, count<<SECTOR_SHIFT)
    cdef void writeBytes(self, unsigned int offset, unsigned int size, bytes data):
        cdef unsigned int oldPos
        if (len(data) < size): # data is too short.
            data += b'\x00'*(size-len(data))
        oldPos = self.fp.tell()
        self.fp.seek(offset)
        retData = self.fp.write(data)
        self.fp.seek(oldPos)
        self.fp.flush()
    cdef void writeSectors(self, unsigned int sector, unsigned int count, bytes data):
        self.writeBytes(sector<<SECTOR_SHIFT, count<<SECTOR_SHIFT, data)
    cdef void run(self):
        self.reset()


cdef class AtaController:
    def __init__(self, Ata ata, object main, unsigned char controllerId):
        self.ata = ata
        self.main = main
        self.controllerId = controllerId
        if (self.controllerId == 0):
            self.irq = ATA1_IRQ
        elif (self.controllerId == 1):
            self.irq = ATA2_IRQ
        else:
            self.irq = None
        self.driveId = 0
        self.drive = (AtaDrive(self, self.main, 0), AtaDrive(self, self.main, 1))
        self.result = self.data = b""
    cdef void reset(self, unsigned char swReset):
        cdef AtaDrive drive
        self.drq = self.err = self.useLBA = self.useLBA48 = False
        self.seekComplete = self.irqEnabled = True
        self.cmd = 0
        if (self.irq):
            (<Pic>self.main.platform.pic).lowerIrq(self.irq)
        if (not swReset):
            self.driveId = 0
            self.doReset = self.driveBusy = self.resetInProgress = False
            self.driveReady = True
        else:
            self.driveReady = False
            self.driveBusy = self.resetInProgress = True
        for drive in self.drive:
            drive.reset()
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef AtaDrive drive
        cdef unsigned char ret = BITMASK_BYTE
        drive = self.drive[self.driveId]
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x0): # data port
                if (not len(self.result)):
                    self.drq = False
                    self.main.notice("AtaController::inPort: data port is empty, returning 0xff; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
                    return ret
                ret = self.result[0]
                self.result = self.result[1:]
                if (not len(self.result)):
                    self.drq = False
            elif (ioPortAddr == 0x2):
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
            elif (ioPortAddr == 0x7):
                if (not drive.isLoaded):
                    self.main.notice("AtaController::inPort: drive isn't loaded: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}; ret: {4:#06x}", self.controllerId, self.driveId, ioPortAddr, dataSize, ret)
                    return 0x00
                ret = (self.driveBusy << 7) | (self.driveReady << 6) | (self.seekComplete << 4) | (self.drq << 3) | \
                    (self.err)
                if (self.irq):
                    (<Pic>self.main.platform.pic).lowerIrq(self.irq)
            elif (ioPortAddr == 0x1fe or ioPortAddr == 0x206):
                ret = (1 << 7) | (self.doReset << 2) | (self.irqEnabled << 1)
            elif (ioPortAddr == 0x1ff or ioPortAddr == 0x207):
                self.main.exitError("AtaController::inPort: what??? ;controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
                return BITMASK_BYTE
            else:
                self.main.notice("AtaController::inPort: TODO: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}; ret: {4:#06x}", self.controllerId, self.driveId, ioPortAddr, dataSize, ret)
        else:
            self.main.exitError("AtaController::inPort: dataSize {0:d} not supported.", dataSize)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef AtaDrive drive
        cdef unsigned char prevReset
        drive = self.drive[self.driveId]
        if (ioPortAddr <= 0x5 and not drive.isLoaded):
            return # ignore write to not loaded device
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x0): # data port
                self.data += bytes([data])
                if (len(self.data) >> SECTOR_SHIFT >= drive.sectorCount):
                    drive.writeSectors(drive.sector, drive.sectorCount, self.data)
                    self.data = self.data[drive.sectorCount << SECTOR_SHIFT:]
                    self.drq = False
            elif (ioPortAddr == 0x1):
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
                drive = self.drive[self.driveId]
                drive.sector = (drive.sector&0xfffff0ffffff)|((data&0xf)<<24)
                self.useLBA = True if ((data & USE_LBA) != 0) else False
                self.useLBA48 = True if ((data & USE_LBA28) != USE_LBA28) else False
            elif (ioPortAddr == 0x7): # command port
                if (drive.isLoaded):
                    self.err = False
                    self.driveBusy = False
                    self.drq = True
                    self.cmd = data
                    if (data == COMMAND_IDENTIFY):
                        self.result = drive.configSpace.csRead(0, SECTOR_SIZE)
                    elif (data == COMMAND_READ_LBA28):
                        self.result = drive.readSectors(drive.sector, drive.sectorCount)
                    elif (data == COMMAND_WRITE_LBA28):
                        pass # not handled here.
                    else:
                        self.main.exitError("AtaController::outPort: unknown command: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
                else:
                    ##self.driveBusy = self.driveReady = self.seekComplete = self.drq = self.err = False
                    self.main.notice("AtaController::outPort: identify command: drive isn't loaded: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
            elif (ioPortAddr == 0x1fe or ioPortAddr == 0x206):
                if (not (data & CONTROL_REG_SHOULD_BE_SET)):
                    self.main.exitError("AtaController::outPort: CONTROL_REG_SHOULD_BE_SET should be set! (obvious message is obvious.)")
                prevReset = self.doReset
                self.irqEnabled = ((data & CONTROL_REG_NIEN) != CONTROL_REG_NIEN)
                self.doReset = ((data & CONTROL_REG_SRST) == CONTROL_REG_SRST)
                if (not prevReset and self.doReset):
                    self.reset(True)
                elif (self.resetInProgress and not self.doReset):
                    self.driveBusy = self.resetInProgress = False
                    self.driveReady = True
            else:
                self.main.notice("AtaController::outPort: TODO: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
        else:
            self.main.exitError("AtaController::outPort: dataSize {0:d} not supported.", dataSize)
        return
    cdef void run(self):
        (<Cmos>self.main.platform.cmos).writeValue(CMOS_HDD_DRIVE_TYPE, 0, OP_SIZE_BYTE)
        if (self.controllerId == 0):
            if (self.main.hdaFilename): (<AtaDrive>self.drive[0]).loadDrive(self.main.hdaFilename)
            if (self.main.hdbFilename): (<AtaDrive>self.drive[1]).loadDrive(self.main.hdbFilename)


cdef class Ata:
    def __init__(self, object main):
        self.main = main
        self.controller = (AtaController(self, self.main, 0), AtaController(self, self.main, 1))
    cdef void reset(self):
        cdef AtaController controller
        for controller in self.controller:
            controller.reset(False)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned int ret = BITMASK_BYTE
        #self.main.notice("Ata::inPort: ioPortAddr: {0:#06x}; dataSize: {1:d}", ioPortAddr, dataSize)
        if (dataSize == OP_SIZE_WORD):
            ret = self.inPort(ioPortAddr, OP_SIZE_BYTE)
            ret |= self.inPort(ioPortAddr, OP_SIZE_BYTE)<<8
            return ret
        elif (dataSize == OP_SIZE_DWORD):
            ret = self.inPort(ioPortAddr, OP_SIZE_WORD)
            ret |= self.inPort(ioPortAddr, OP_SIZE_WORD)<<16
            return ret
        if (ioPortAddr in ATA1_PORTS and len(self.controller) >= 1 and self.controller[0]):
            ret = (<AtaController>self.controller[0]).inPort(ioPortAddr-ATA1_BASE, dataSize)
        elif (ioPortAddr in ATA2_PORTS and len(self.controller) >= 2 and self.controller[1]):
            ret = (<AtaController>self.controller[1]).inPort(ioPortAddr-ATA2_BASE, dataSize)
        elif (ioPortAddr in ATA3_PORTS and len(self.controller) >= 3 and self.controller[2]):
            ret = (<AtaController>self.controller[2]).inPort(ioPortAddr-ATA3_BASE, dataSize)
        elif (ioPortAddr in ATA4_PORTS and len(self.controller) >= 4 and self.controller[3]):
            ret = (<AtaController>self.controller[3]).inPort(ioPortAddr-ATA4_BASE, dataSize)
        #self.main.notice("Ata::inPort: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#04x}", ioPortAddr, dataSize, ret)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        #self.main.notice("Ata::outPort: ioPortAddr: {0:#06x}; data: {1:#04x}; dataSize: {2:d}", ioPortAddr, data, dataSize)
        if (dataSize == OP_SIZE_WORD):
            self.outPort(ioPortAddr, (data>>8)&BITMASK_BYTE, OP_SIZE_BYTE)
            self.outPort(ioPortAddr, data&BITMASK_BYTE, OP_SIZE_BYTE)
            return
        elif (dataSize == OP_SIZE_DWORD):
            self.outPort(ioPortAddr, (data>>16)&BITMASK_WORD, OP_SIZE_WORD)
            self.outPort(ioPortAddr, data&BITMASK_WORD, OP_SIZE_WORD)
            return
        if (ioPortAddr in ATA1_PORTS and len(self.controller) >= 1 and self.controller[0]):
            (<AtaController>self.controller[0]).outPort(ioPortAddr-ATA1_BASE, data, dataSize)
        elif (ioPortAddr in ATA2_PORTS and len(self.controller) >= 2 and self.controller[1]):
            (<AtaController>self.controller[1]).outPort(ioPortAddr-ATA2_BASE, data, dataSize)
        elif (ioPortAddr in ATA3_PORTS and len(self.controller) >= 3 and self.controller[2]):
            (<AtaController>self.controller[2]).outPort(ioPortAddr-ATA3_BASE, data, dataSize)
        elif (ioPortAddr in ATA4_PORTS and len(self.controller) >= 4 and self.controller[3]):
            (<AtaController>self.controller[3]).outPort(ioPortAddr-ATA4_BASE, data, dataSize)
    cdef void run(self):
        cdef AtaController controller
        for controller in self.controller:
            controller.run()


