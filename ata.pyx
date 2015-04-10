
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"

from os import access, F_OK, R_OK, W_OK, SEEK_END
from os.path import getsize


DEF HEADS = 16
DEF SPT = 63

DEF ATA_DRIVE_TYPE_NONE = 0
DEF ATA_DRIVE_TYPE_HD = 1
DEF ATA_DRIVE_TYPE_CDROM = 2


DEF ATA1_BASE = 0x1f0
DEF ATA1_CTRL_BASE = 0x3f4
DEF ATA2_BASE = 0x170
DEF ATA2_CTRL_BASE = 0x374
DEF ATA3_BASE = 0x1e8
DEF ATA3_CTRL_BASE = 0x3ec
DEF ATA4_BASE = 0x168
DEF ATA4_CTRL_BASE = 0x36c

DEF ATA1_IRQ = 14
DEF ATA2_IRQ = 15

DEF SELECT_SLAVE_DRIVE = 0x10
DEF USE_LBA = 0x40
DEF USE_LBA28 = 0xa0
DEF CONTROL_REG_HOB = 0x80
DEF CONTROL_REG_SRST = 0x4
DEF CONTROL_REG_NIEN = 0x2

DEF COMMAND_RESET = 0x08
DEF COMMAND_RECALIBRATE = 0x10
DEF COMMAND_READ_LBA28 = 0x20
DEF COMMAND_WRITE_LBA28 = 0x30
DEF COMMAND_INITIALIZE_DRIVE_PARAMETERS = 0x91
DEF COMMAND_PACKET = 0xa0
DEF COMMAND_IDENTIFY_DEVICE_PACKET = 0xa1
DEF COMMAND_IDENTIFY_DEVICE = 0xec

DEF PACKET_COMMAND_TEST_UNIT_READY = 0x00
DEF PACKET_COMMAND_REQUEST_SENSE = 0x03
DEF PACKET_COMMAND_INQUIRY = 0x12
DEF PACKET_COMMAND_START_STOP_UNIT = 0x1b
DEF PACKET_COMMAND_READ_CAPACITY = 0x25
DEF PACKET_COMMAND_READ_10 = 0x28
DEF PACKET_COMMAND_READ_12 = 0xa8

DEF FD_HD_SECTOR_SIZE = 512
DEF FD_HD_SECTOR_SHIFT = 9

DEF CD_SECTOR_SIZE = 2048
DEF CD_SECTOR_SHIFT = 11

cdef class AtaDrive:
    def __init__(self, AtaController ataController, unsigned char driveId, unsigned char driveType):
        self.ataController = ataController
        self.driveId = driveId
        self.driveType = driveType
        self.isLoaded = False
        self.isWriteProtected = True
        self.sectors = 0
        if (self.driveType == ATA_DRIVE_TYPE_CDROM):
            self.sectorShift = CD_SECTOR_SHIFT
            self.sectorSize = CD_SECTOR_SIZE
            self.driveCode = 0xeb14
        else:
            self.sectorShift = FD_HD_SECTOR_SHIFT
            self.sectorSize = FD_HD_SECTOR_SIZE
            self.driveCode = 0x0
        self.configSpace = ConfigSpace(512, self.ataController.ata.main)
    cdef unsigned long int ChsToSector(self, unsigned int cylinder, unsigned char head, unsigned char sector):
        return (cylinder*HEADS+head)*SPT+(sector-1)
    cdef inline unsigned short readValue(self, unsigned char index):
        return self.configSpace.csReadValueUnsigned(index << 1, OP_SIZE_WORD)
    cdef inline void writeValue(self, unsigned char index, unsigned short value):
        self.configSpace.csWriteValue(index << 1, value, OP_SIZE_WORD)
    cdef void reset(self):
        pass
    cdef void loadDrive(self, bytes filename):
        cdef unsigned char cmosDiskType, translateReg, translateValue, translateValueTemp
        cdef unsigned int cylinders
        if (not filename):
            self.ataController.ata.main.notice("HD{0:d}: loadDrive: file isn't found/accessable.", (self.ataController.controllerId << 1)+self.driveId)
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
            self.ataController.ata.main.notice("HD{0:d}: loadDrive: file isn't found/accessable. (filename: {1:s}, access-cmd)", (self.ataController.controllerId << 1)+self.driveId, filename.decode())
            return
        self.fp.seek(0, SEEK_END)
        self.sectors = self.fp.tell() >> self.sectorShift
        self.fp.seek(0)
        cylinders = self.sectors / (HEADS * SPT)
        if (cylinders > 16383):
            cylinders = 16383
        if (self.ataController.controllerId == 0 and self.driveId in (0, 1)):
            self.writeValue(1, cylinders) # word 1 ; cylinders
            self.writeValue(3, HEADS) # word 3 ; heads
            self.writeValue(4, SPT << self.sectorShift) # word 4 ; spt * self.sectorSize
            self.writeValue(5, self.sectorSize) # hdd block size
            self.writeValue(6, SPT) # word 6 ; spt
            self.writeValue(20, 2) # type
            self.writeValue(21, self.sectorSize) # increment in hdd block size
            self.writeValue(83, (1 << 10)) # supports lba48
            self.writeValue(86, (1 << 10)) # supports lba48
            if (not self.driveId):
                self.writeValue(93, (1 << 12)) # is master drive
            self.writeValue(60, <unsigned short>self.sectors) # total number of addressable blocks.
            self.configSpace.csWriteValue(100 << 1, self.sectors, OP_SIZE_QWORD) # total number of addressable blocks.
        self.writeValue(48, 1) # supports dword access
        self.writeValue(49, (1 << 9)) # supports lba
        #if (cylinders <= 1024): # hardcoded
        if (cylinders <= 2048): # hardcoded
            translateValueTemp = ATA_TRANSLATE_NONE
        elif ((cylinders * HEADS) <= 131072):
            translateValueTemp = ATA_TRANSLATE_LARGE
        else:
            translateValueTemp = ATA_TRANSLATE_LBA
        translateReg = CMOS_ATA_0_1_TRANSLATION if (self.ataController.controllerId in (0, 1)) else CMOS_ATA_2_3_TRANSLATION
        translateValue = (<Cmos>self.ataController.ata.main.platform.cmos).readValue(translateReg, OP_SIZE_BYTE)
        translateValue |= (translateValueTemp << (((self.ataController.controllerId&1)<<2)+(self.driveId<<1)))
        (<Cmos>self.ataController.ata.main.platform.cmos).writeValue(translateReg, translateValue, OP_SIZE_BYTE)
        if (self.ataController.controllerId == 0 and self.driveId in (0, 1)):
            self.writeValue(0, 0xff80) # word 0 ; ata; fixed drive
            cmosDiskType = (<Cmos>self.ataController.ata.main.platform.cmos).readValue(CMOS_HDD_DRIVE_TYPE, OP_SIZE_BYTE)
            cmosDiskType |= (0xf0 if (self.driveId == 0) else 0x0f)
            (<Cmos>self.ataController.ata.main.platform.cmos).writeValue(CMOS_HDD_DRIVE_TYPE, cmosDiskType, OP_SIZE_BYTE)
            (<Cmos>self.ataController.ata.main.platform.cmos).writeValue((CMOS_HD0_EXTENDED_DRIVE_TYPE if (self.driveId == 0) else CMOS_HD1_EXTENDED_DRIVE_TYPE), 0x2f, OP_SIZE_BYTE)
            (<Cmos>self.ataController.ata.main.platform.cmos).writeValue((CMOS_HD0_CYLINDERS if (self.driveId == 0) else CMOS_HD1_CYLINDERS), cylinders, OP_SIZE_WORD)
            (<Cmos>self.ataController.ata.main.platform.cmos).writeValue((CMOS_HD0_LANDING_ZONE if (self.driveId == 0) else CMOS_HD1_LANDING_ZONE), cylinders, OP_SIZE_WORD)
            (<Cmos>self.ataController.ata.main.platform.cmos).writeValue((CMOS_HD0_WRITE_PRECOMP if (self.driveId == 0) else CMOS_HD1_WRITE_PRECOMP), 0xffff, OP_SIZE_WORD)
            (<Cmos>self.ataController.ata.main.platform.cmos).writeValue((CMOS_HD0_HEADS if (self.driveId == 0) else CMOS_HD1_HEADS), HEADS, OP_SIZE_BYTE)
            (<Cmos>self.ataController.ata.main.platform.cmos).writeValue((CMOS_HD0_SPT if (self.driveId == 0) else CMOS_HD1_SPT), SPT, OP_SIZE_BYTE)
            if (self.driveId == 0):
                (<Cmos>self.ataController.ata.main.platform.cmos).writeValue(CMOS_HD0_CONTROL_BYTE, 0xc8, OP_SIZE_BYTE) # hardcoded
                self.ataController.ata.pciDevice.setData(0x40, 0x80, OP_SIZE_WORD)
            else:
                (<Cmos>self.ataController.ata.main.platform.cmos).writeValue(CMOS_HD1_CONTROL_BYTE, 0x80, OP_SIZE_BYTE) # hardcoded
                self.ataController.ata.pciDevice.setData(0x42, 0x80, OP_SIZE_WORD)
        else:
            self.writeValue(0, 0x85c0) # word 0 ; atapi; removable drive
            self.writeValue(85, (1 << 4)) # supports packet
    cdef bytes readBytes(self, unsigned long int offset, unsigned int size):
        cdef bytes data
        cdef unsigned long int oldPos
        oldPos = self.fp.tell()
        self.fp.seek(offset)
        data = self.fp.read(size)
        if (len(data) < size): # floppy image is too short.
            data += b'\x00'*(size-len(data))
        self.fp.seek(oldPos)
        return data
    cdef bytes readSectors(self, unsigned long int sector, unsigned int count): # count in sectors
        return self.readBytes(sector << self.sectorShift, count << self.sectorShift)
    cdef void writeBytes(self, unsigned long int offset, unsigned int size, bytes data):
        cdef unsigned long int oldPos
        if (self.driveType == ATA_DRIVE_TYPE_CDROM):
            self.ataController.ata.main.exitError("AtaDrive::writeBytes: tried to write to optical drive!")
            return
        if (len(data) < size): # data is too short.
            data += b'\x00'*(size-len(data))
        oldPos = self.fp.tell()
        self.fp.seek(offset)
        retData = self.fp.write(data)
        self.fp.seek(oldPos)
        self.fp.flush()
    cdef void writeSectors(self, unsigned long int sector, unsigned int count, bytes data):
        self.writeBytes(sector << self.sectorShift, count << self.sectorShift, data)
    cdef void run(self):
        pass


cdef class AtaController:
    def __init__(self, Ata ata, unsigned char controllerId):
        cdef unsigned char driveType # HACK
        self.ata = ata
        self.controllerId = controllerId
        if (self.controllerId == 0):
            self.irq = ATA1_IRQ
            driveType = ATA_DRIVE_TYPE_HD
        elif (self.controllerId == 1):
            self.irq = ATA2_IRQ
            driveType = ATA_DRIVE_TYPE_CDROM
        else:
            self.irq = None
            driveType = ATA_DRIVE_TYPE_NONE
        self.driveId = 0
        self.drive = (AtaDrive(self, 0, driveType), AtaDrive(self, 1, driveType))
        self.result = self.data = b''
    cdef void reset(self, unsigned char swReset):
        cdef AtaDrive drive
        self.drq = self.err = self.useLBA = self.useLBA48 = self.HOB = False
        self.seekComplete = self.irqEnabled = True
        self.cmd = 0
        self.errorRegister = 1
        if (self.irq):
            (<Pic>self.ata.main.platform.pic).lowerIrq(self.irq)
        if (not swReset):
            self.doReset = self.driveBusy = self.resetInProgress = False
            self.driveReady = True
        else:
            self.driveReady = False
            self.driveBusy = self.resetInProgress = True
        for drive in self.drive:
            drive.reset()
    cdef inline void LbaToCHS(self):
        self.cylinder = self.lba / (HEADS*SPT)
        self.head = (self.lba / SPT) % HEADS
        self.sector = (self.lba % SPT) + 1
    cdef void convertToLBA28(self):
        if (self.useLBA and self.useLBA48):
            self.sectorCount >>= 8
            self.lba >>= 24
            self.lba = (self.lba & 0xffffff) | (<unsigned long int>(self.head) << 24)
            if (not self.sectorCount):
                self.sectorCount = BITMASK_BYTE+1
    cdef void raiseAtaIrq(self):
        if (self.irq and self.irqEnabled):
            (<Pic>self.ata.main.platform.pic).raiseIrq(self.irq)
        self.drq = True
        self.driveBusy = self.err = False
        self.errorRegister = 0
    cdef void lowerAtaIrq(self):
        self.driveReady = True
        self.drq = self.err = False
        self.errorRegister = 0
    cdef void abortCommand(self):
        self.errorCommand(0x04)
        if (self.irq):
            (<Pic>self.ata.main.platform.pic).raiseIrq(self.irq)
    cdef void errorCommand(self, unsigned char errorRegister):
        cdef AtaDrive drive
        drive = self.drive[self.driveId]
        self.cmd = 0
        self.driveBusy = self.drq = self.seekComplete = self.driveReady = False
        self.err = True
        self.errorRegister = errorRegister
        self.result = self.data = b''
        if (self.errorRegister == 0x2): # NO MEDIA
            self.cylinder = BITMASK_WORD
        #elif (self.errorRegister == 0x4): # ABORTED
        else:
            self.cylinder = drive.driveCode
            self.driveReady = self.seekComplete = True
        self.lba = self.cylinder = self.sectorCount = BITMASK_WORD
        self.head = self.sector = BITMASK_BYTE
    cdef void handlePacket(self):
        cdef AtaDrive drive
        cdef unsigned char cmd, dataSize
        cdef unsigned int sectorCount
        cdef unsigned long int lba
        drive = self.drive[self.driveId]
        cmd = self.data[0]
        #self.ata.main.notice("AtaController::handlePacket_0: self.data == {0:s}", repr(self.data))
        if (not drive.isLoaded):
            self.ata.main.notice("AtaController::handlePacket: drive is not loaded! self.data == {0:s}", repr(self.data))
            self.errorCommand(0x2)
        if (cmd == PACKET_COMMAND_TEST_UNIT_READY):
            self.result = b'\x00'*8
        elif (cmd == PACKET_COMMAND_REQUEST_SENSE):
            #self.ata.main.exitError("AtaController::handlePacket_3: test exit! self.data == {0:s}", repr(self.data))
            self.result = b'\x00'*12
            if (not drive.isLoaded):
                self.result += b'\x3a\x00\x04\x01\x00\x00'
            else:
                self.result += b'\x00'*6
        elif (cmd == PACKET_COMMAND_INQUIRY):
            dataSize = self.data[4]
            if (dataSize < 36):
                self.ata.main.exitError("AtaController::handlePacket_6: allocation length is < 36! self.data == {0:s}", repr(self.data))
                return
            if (drive.driveType == ATA_DRIVE_TYPE_CDROM):
                self.result = drive.readValue(0).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
            else:
                self.result = b'\x00'*2
            self.result += b'\x00\x21'
            self.result += bytes([dataSize-5])
            self.result += b'\x00'*(dataSize-5)
        elif (cmd == PACKET_COMMAND_START_STOP_UNIT):
            pass
        elif (cmd == PACKET_COMMAND_READ_CAPACITY):
            lba = drive.sectors - 1 # TODO: FIXME: 0-based?
            if (lba > BITMASK_DWORD):
                lba = BITMASK_DWORD
            self.result = lba.to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
            self.result += (CD_SECTOR_SIZE).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
        elif (cmd == PACKET_COMMAND_READ_10):
            lba = int.from_bytes(self.data[2:2+OP_SIZE_DWORD], byteorder="big", signed=False)
            sectorCount = int.from_bytes(self.data[7:7+OP_SIZE_WORD], byteorder="big", signed=False)
            self.result = drive.readSectors(lba, sectorCount)
        elif (cmd == PACKET_COMMAND_READ_12):
            lba = int.from_bytes(self.data[2:2+OP_SIZE_DWORD], byteorder="big", signed=False)
            sectorCount = int.from_bytes(self.data[6:6+OP_SIZE_DWORD], byteorder="big", signed=False)
            self.result = drive.readSectors(lba, sectorCount)
        else:
            self.ata.main.exitError("AtaController::handlePacket: cmd is unknown! cmd == {0:#04x}, self.data == {1:s}", cmd, repr(self.data))
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef AtaDrive drive
        cdef unsigned int ret
        ret = BITMASKS_FF[dataSize]
        drive = self.drive[self.driveId]
        if (ioPortAddr == 0x0): # data port
            if (not drive.isLoaded):
                #self.ata.main.notice("AtaController::inPort_1: drive is not loaded, returning BITMASK_BYTE; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
                self.errorCommand(0x2)
                return ret
            if (not self.drq):
                self.ata.main.exitError("AtaController::inPort_1: not self.drq, returning BITMASK_BYTE; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
                return ret
            if (len(self.result) < dataSize):
                self.ata.main.exitError("AtaController::inPort_1: len(self.result) < dataSize; data port is empty, returning BITMASK_BYTE; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
                return ret
            ret = int.from_bytes(self.result[0:dataSize], byteorder="little", signed=False)
            self.result = self.result[dataSize:]
            if (not (len(self.result) % drive.sectorSize)):
                self.lba += 1 # TODO
                self.sectorCount -= 1
                self.LbaToCHS()
                if (len(self.result)):
                    self.raiseAtaIrq()
                else:
                    self.lowerAtaIrq()
            return ret
        elif (dataSize == OP_SIZE_BYTE):
            if (not drive.isLoaded):
                #self.ata.main.notice("AtaController::inPort_2: drive is not loaded, returning BITMASK_BYTE; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
                self.errorCommand(0x2)
            #if (ioPortAddr >= 0x1 and ioPortAddr <= 0x5 and not drive.isLoaded):
            #    return 0
            if (ioPortAddr == 0x1):
                return self.errorRegister
            elif (ioPortAddr == 0x2):
                if (self.cmd == COMMAND_PACKET and not len(self.result)):
                    self.sectorCount = 3
                elif (self.useLBA):
                    if (self.HOB and self.useLBA48):
                        return ((self.sectorCount & 0xff00) >> 8)
                    return (self.sectorCount & 0x00ff)
                ret = <unsigned char>self.sectorCount
            elif (ioPortAddr == 0x3):
                if (self.useLBA):
                    if (self.HOB and self.useLBA48):
                        return ((self.lba & 0x0000ff000000) >> 24)
                    return (self.lba & 0x0000000000ff)
                ret = <unsigned char>self.sector
            elif (ioPortAddr == 0x4):
                if (self.cmd == COMMAND_PACKET and len(self.result) <= BITMASK_WORD):
                    self.cylinder = len(self.result) # return length
                elif (self.useLBA):
                    if (self.HOB and self.useLBA48):
                        return ((self.lba & 0x00ff00000000) >> 32)
                    return ((self.lba & 0x00000000ff00) >> 8)
                ret = <unsigned char>self.cylinder
            elif (ioPortAddr == 0x5):
                if (self.cmd == COMMAND_PACKET and len(self.result) <= BITMASK_WORD):
                    self.cylinder = len(self.result) # return length
                elif (self.useLBA):
                    if (self.HOB and self.useLBA48):
                        return ((self.lba & 0xff0000000000) >> 40)
                    return ((self.lba & 0x000000ff0000) >> 16)
                ret = <unsigned char>(self.cylinder >> 8)
            elif (ioPortAddr == 0x6):
                ret = (0xa0) | (self.useLBA << 6) | (self.driveId << 4) | (((self.lba >> 24) if (self.useLBA) else self.head) & 0xf)
            elif (ioPortAddr == 0x7 or ioPortAddr == 0x1fe or ioPortAddr == 0x206):
                if (ioPortAddr == 0x7 and self.irq):
                    (<Pic>self.ata.main.platform.pic).lowerIrq(self.irq)
                if (not drive.isLoaded):
                    #self.ata.main.notice("AtaController::inPort: drive isn't loaded: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
                    self.errorCommand(0x2)
                ret = (self.driveBusy << 7) | (self.driveReady << 6) | (self.seekComplete << 4) | (self.drq << 3) | (self.err)
            elif (ioPortAddr == 0x1ff or ioPortAddr == 0x207):
                self.ata.main.exitError("AtaController::inPort: what??? ;controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
            else:
                self.ata.main.exitError("AtaController::inPort: TODO: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
        else:
            self.ata.main.exitError("AtaController::inPort: dataSize {0:d} not supported.", dataSize)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef AtaDrive drive
        cdef unsigned char prevReset
        drive = self.drive[self.driveId]
        if (ioPortAddr == 0x0): # data port
            self.data += (data).to_bytes(length=dataSize, byteorder="little", signed=False)
            if (self.cmd == COMMAND_WRITE_LBA28):
                if (not self.drq):
                    self.ata.main.exitError("AtaController::outPort_1: not self.drq, returning; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
                    return
                if (len(self.data) >= drive.sectorSize):
                    drive.writeSectors(self.lba, 1, self.data)
                    self.data = self.data[drive.sectorSize:]
                    self.lba += 1 # TODO
                    self.sectorCount -= 1
                    self.LbaToCHS()
                    if (self.sectorCount):
                        self.raiseAtaIrq()
                    else:
                        self.lowerAtaIrq()
            elif (self.cmd == COMMAND_PACKET):
                self.ata.main.debug("AtaController::outPort_0: len(self.data) == {0:d}, self.data == {1:s}", len(self.data), repr(self.data))
                if (len(self.data) >= 12):
                    self.handlePacket()
                    if (not self.err):
                        self.raiseAtaIrq()
                else:
                    self.lowerAtaIrq()
            else:
                self.ata.main.exitError("AtaController::outPort: unknown command 1: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}; cmd: {5:#04x}", self.controllerId, self.driveId, ioPortAddr, data, dataSize, self.cmd)
        elif (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x1):
                pass # unimplemented: to be used for the set features command (0xef)
                #if (data):
                #    self.ata.main.notice("AtaController::outPort: overlapping packet and/or DMA is not supported yet: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
            elif (ioPortAddr == 0x2):
                if (self.useLBA and self.useLBA48):
                    if (not self.sectorCountFlipFlop):
                        self.sectorCount = (self.sectorCount & 0x00ff) | ((<unsigned char>data) << 8)
                    else:
                        self.sectorCount = (self.sectorCount & 0xff00) | (<unsigned char>data)
                    self.sectorCountFlipFlop = not self.sectorCountFlipFlop
                else:
                    self.sectorCount = (<unsigned char>data)
            elif (ioPortAddr == 0x3):
                if (self.useLBA and self.useLBA48):
                    if (not self.sectorLowFlipFlop):
                        self.lba = (self.lba & 0xffff00ffffff) | (<unsigned long int>(<unsigned char>data) << 24)
                    else:
                        self.lba = (self.lba & 0xffffffffff00) | (<unsigned char>data)
                    self.sectorLowFlipFlop = not self.sectorLowFlipFlop
                else:
                    self.lba = (self.lba & 0xffff00) | (<unsigned char>data)
                self.sector = (<unsigned char>data)
            elif (ioPortAddr == 0x4):
                if (self.useLBA and self.useLBA48):
                    if (not self.sectorMiddleFlipFlop):
                        self.lba = (self.lba & 0xff00ffffffff) | (<unsigned long int>(<unsigned char>data) << 32)
                    else:
                        self.lba = (self.lba & 0xffffffff00ff) | ((<unsigned char>data) << 8)
                    self.sectorMiddleFlipFlop = not self.sectorMiddleFlipFlop
                else:
                    self.lba = (self.lba & 0xff00ff) | ((<unsigned char>data) << 8)
                self.cylinder = (self.cylinder & 0xff00) | (<unsigned char>data)
            elif (ioPortAddr == 0x5):
                if (self.useLBA and self.useLBA48):
                    if (not self.sectorHighFlipFlop):
                        self.lba = (self.lba & 0x00ffffffffff) | (<unsigned long int>(<unsigned char>data) << 40)
                    else:
                        self.lba = (self.lba & 0xffffff00ffff) | ((<unsigned char>data) << 16)
                    self.sectorHighFlipFlop = not self.sectorHighFlipFlop
                else:
                    self.lba = (self.lba & 0x00ffff) | ((<unsigned char>data) << 16)
                self.cylinder = (self.cylinder & 0x00ff) | ((<unsigned char>data) << 8)
            elif (ioPortAddr == 0x6):
                self.driveId = ((data & SELECT_SLAVE_DRIVE) == SELECT_SLAVE_DRIVE)
                drive = self.drive[self.driveId]
                self.useLBA = ((data & USE_LBA) == USE_LBA)
                self.useLBA48 = ((data & USE_LBA28) != USE_LBA28)
                self.head = data & 0xf
            elif (ioPortAddr == 0x7): # command port
                if (self.driveId and not drive.isLoaded):
                    self.ata.main.debug("AtaController::outPort: selected slave, but it's not present; return")
                    return
                if (self.irq):
                    (<Pic>self.ata.main.platform.pic).lowerIrq(self.irq)
                if (not drive.isLoaded):
                    self.ata.main.notice("AtaController::outPort: it's not present; return")
                    self.errorCommand(0x2)
                    return
                self.cmd = data
                self.result = self.data = b''
                if (not self.sectorCount):
                    if (self.useLBA and self.useLBA48):
                        self.sectorCount = BITMASK_WORD+1
                    else:
                        self.sectorCount = BITMASK_BYTE+1
                if (not self.useLBA):
                    self.lba = drive.ChsToSector(self.cylinder, self.head, self.sector)
                    self.ata.main.debug("AtaController::outPort: test3: lba=={0:d}, cylinder=={1:d}, head=={2:d}, sector=={3:d}", self.lba, self.cylinder, self.head, self.sector)
                if (data == COMMAND_RESET):
                    self.result = b'\x00\x01\x01'
                    self.result += (drive.driveCode).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
                    self.result += b'\x00'
                elif ((data & 0xf0) == COMMAND_RECALIBRATE):
                    pass # do nothing here
                elif (data in (COMMAND_IDENTIFY_DEVICE, COMMAND_IDENTIFY_DEVICE_PACKET)):
                    if ((self.controllerId == 0 and data == COMMAND_IDENTIFY_DEVICE_PACKET) or (self.controllerId == 1 and data == COMMAND_IDENTIFY_DEVICE)):
                        self.abortCommand()
                        return
                    self.result = drive.configSpace.csRead(0, 512)
                elif (data == COMMAND_READ_LBA28):
                    self.convertToLBA28()
                    self.result = drive.readSectors(self.lba, self.sectorCount)
                elif (data in (COMMAND_WRITE_LBA28, COMMAND_PACKET)):
                    if (data == COMMAND_WRITE_LBA28):
                        self.convertToLBA28()
                    pass # not handled here.
                elif (data == COMMAND_INITIALIZE_DRIVE_PARAMETERS):
                    self.sectorCount = SPT
                    self.head = HEADS-1
                else:
                    self.ata.main.exitError("AtaController::outPort: unknown command 2: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
                    return
                self.raiseAtaIrq()
            elif (ioPortAddr == 0x1fe or ioPortAddr == 0x206):
                prevReset = self.doReset
                self.irqEnabled = ((data & CONTROL_REG_NIEN) != CONTROL_REG_NIEN)
                self.doReset = ((data & CONTROL_REG_SRST) == CONTROL_REG_SRST)
                self.HOB = ((data & CONTROL_REG_HOB) == CONTROL_REG_HOB)
                self.ata.main.debug("AtaController::outPort: test2: prevReset=={0:d}; doReset=={1:d}; resetInProgress=={2:d}; irqEnabled=={3:d}; HOB=={4:d}", prevReset, self.doReset, self.resetInProgress, self.irqEnabled, self.HOB)
                self.lba = self.head = 0
                self.cylinder = drive.driveCode
                self.sectorCount = self.sector = 1
                self.sectorCountFlipFlop = self.sectorHighFlipFlop = self.sectorMiddleFlipFlop = self.sectorLowFlipFlop = False
                if (not prevReset and self.doReset):
                    self.reset(True)
                elif (self.resetInProgress and not self.doReset):
                    self.driveBusy = self.resetInProgress = False
                    self.driveReady = True
            else:
                self.ata.main.exitError("AtaController::outPort: TODO: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
        else:
            self.ata.main.exitError("AtaController::outPort: dataSize {0:d} not supported.", dataSize)
    cdef void run(self):
        if (self.controllerId == 0):
            if (self.ata.main.hdaFilename): (<AtaDrive>self.drive[0]).loadDrive(self.ata.main.hdaFilename)
            if (self.ata.main.hdbFilename): (<AtaDrive>self.drive[1]).loadDrive(self.ata.main.hdbFilename)
        elif (self.controllerId == 1):
            if (self.ata.main.cdromFilename): (<AtaDrive>self.drive[0]).loadDrive(self.ata.main.cdromFilename)


cdef class Ata:
    def __init__(self, Hirnwichse main):
        self.main = main
        self.controller = (AtaController(self, 0), AtaController(self, 1))
        self.pciDevice = (<Pci>self.main.platform.pci).addDevice()
        self.pciDevice.setVendorDeviceId(0x8086, 0x7010)
        self.pciDevice.setDeviceClass(PCI_CLASS_PATA)
    cdef void reset(self):
        cdef AtaController controller
        for controller in self.controller:
            controller.reset(False)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned int ret = BITMASKS_FF[dataSize]
        self.main.debug("Ata::inPort1: ioPortAddr: {0:#06x}; dataSize: {1:d}", ioPortAddr, dataSize)
        if (dataSize == OP_SIZE_WORD and (ioPortAddr&0xf)):
            ret = self.inPort(ioPortAddr, OP_SIZE_BYTE)
            ret |= self.inPort(ioPortAddr, OP_SIZE_BYTE) << 8
            self.main.debug("Ata::inPort2: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#06x}", ioPortAddr, dataSize, ret)
            return ret
        elif (dataSize == OP_SIZE_DWORD and (ioPortAddr&0xf)):
            ret = self.inPort(ioPortAddr, OP_SIZE_WORD)
            ret |= self.inPort(ioPortAddr, OP_SIZE_WORD) << 16
            self.main.debug("Ata::inPort3: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#010x}", ioPortAddr, dataSize, ret)
            return ret
        if (ioPortAddr in ATA1_PORTS and len(self.controller) >= 1 and self.controller[0]):
            ret = (<AtaController>self.controller[0]).inPort(ioPortAddr-ATA1_BASE, dataSize)
        elif (ioPortAddr in ATA2_PORTS and len(self.controller) >= 2 and self.controller[1]):
            ret = (<AtaController>self.controller[1]).inPort(ioPortAddr-ATA2_BASE, dataSize)
        #elif (ioPortAddr in ATA3_PORTS and len(self.controller) >= 3 and self.controller[2]):
        #    ret = (<AtaController>self.controller[2]).inPort(ioPortAddr-ATA3_BASE, dataSize)
        #elif (ioPortAddr in ATA4_PORTS and len(self.controller) >= 4 and self.controller[3]):
        #    ret = (<AtaController>self.controller[3]).inPort(ioPortAddr-ATA4_BASE, dataSize)
        self.main.debug("Ata::inPort4: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#04x}", ioPortAddr, dataSize, ret)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        self.main.debug("Ata::outPort: ioPortAddr: {0:#06x}; data: {1:#04x}; dataSize: {2:d}", ioPortAddr, data, dataSize)
        if (dataSize == OP_SIZE_WORD and (ioPortAddr&0xf)):
            self.outPort(ioPortAddr, <unsigned char>data, OP_SIZE_BYTE)
            self.outPort(ioPortAddr, <unsigned char>(data >> 8), OP_SIZE_BYTE)
            return
        elif (dataSize == OP_SIZE_DWORD and (ioPortAddr&0xf)):
            self.outPort(ioPortAddr, <unsigned short>data, OP_SIZE_WORD)
            self.outPort(ioPortAddr, <unsigned short>(data >> 16), OP_SIZE_WORD)
            return
        if (ioPortAddr in ATA1_PORTS and len(self.controller) >= 1 and self.controller[0]):
            (<AtaController>self.controller[0]).outPort(ioPortAddr-ATA1_BASE, data, dataSize)
        elif (ioPortAddr in ATA2_PORTS and len(self.controller) >= 2 and self.controller[1]):
            (<AtaController>self.controller[1]).outPort(ioPortAddr-ATA2_BASE, data, dataSize)
        #elif (ioPortAddr in ATA3_PORTS and len(self.controller) >= 3 and self.controller[2]):
        #    (<AtaController>self.controller[2]).outPort(ioPortAddr-ATA3_BASE, data, dataSize)
        #elif (ioPortAddr in ATA4_PORTS and len(self.controller) >= 4 and self.controller[3]):
        #    (<AtaController>self.controller[3]).outPort(ioPortAddr-ATA4_BASE, data, dataSize)
    cdef void run(self):
        cdef AtaController controller
        #self.reset()
        for controller in self.controller:
            controller.reset(False)
            controller.run()


