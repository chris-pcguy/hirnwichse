
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"

from os import access, F_OK, R_OK, W_OK, SEEK_END
from os.path import getsize, samefile


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
DEF COMMAND_READ_LBA28_WITHOUT_RETRIES = 0x21
DEF COMMAND_READ_LBA48 = 0x24
DEF COMMAND_READ_MULTIPLE_LBA48 = 0x29
DEF COMMAND_READ_MULTIPLE_LBA28 = 0xc4
DEF COMMAND_READ_DMA = 0xc8
DEF COMMAND_READ_DMA_EXT = 0x25

DEF COMMAND_VERIFY_SECTORS_LBA48 = 0x42
DEF COMMAND_VERIFY_SECTORS_LBA28 = 0x40
DEF COMMAND_VERIFY_SECTORS_LBA28_NO_RETRY = 0x41


DEF COMMAND_READ_NATIVE_MAX_ADDRESS = 0xf8
DEF COMMAND_READ_NATIVE_MAX_ADDRESS_EXT = 0x27
DEF COMMAND_SET_MAX_ADDRESS = 0xf9
DEF COMMAND_WRITE_LBA28 = 0x30
DEF COMMAND_WRITE_LBA48 = 0x34
DEF COMMAND_WRITE_MULTIPLE_LBA48 = 0x39
DEF COMMAND_WRITE_MULTIPLE_LBA28 = 0xc5
DEF COMMAND_WRITE_DMA = 0xca
DEF COMMAND_WRITE_DMA_EXT = 0x35
DEF COMMAND_WRITE_DMA_FUA_EXT = 0x3d

DEF COMMAND_EXECUTE_DRIVE_DIAGNOSTIC = 0x90
DEF COMMAND_INITIALIZE_DRIVE_PARAMETERS = 0x91
DEF COMMAND_PACKET = 0xa0
DEF COMMAND_IDENTIFY_DEVICE_PACKET = 0xa1
DEF COMMAND_SET_MULTIPLE_MODE = 0xc6
DEF COMMAND_IDENTIFY_DEVICE = 0xec
DEF COMMAND_SET_FEATURES = 0xef

DEF COMMAND_MEDIA_LOCK = 0xde
DEF COMMAND_MEDIA_UNLOCK = 0xdf

DEF COMMAND_CHECK_POWER_MODE = 0xe5

DEF PACKET_COMMAND_TEST_UNIT_READY = 0x00
DEF PACKET_COMMAND_REQUEST_SENSE = 0x03
DEF PACKET_COMMAND_INQUIRY = 0x12
DEF PACKET_COMMAND_MODE_SENSE_6 = 0x1a
DEF PACKET_COMMAND_START_STOP_UNIT = 0x1b
DEF PACKET_COMMAND_READ_CAPACITY = 0x25
DEF PACKET_COMMAND_READ_10 = 0x28
DEF PACKET_COMMAND_READ_12 = 0xa8
DEF PACKET_COMMAND_READ_SUBCHANNEL = 0x42
DEF PACKET_COMMAND_READ_TOC = 0x43
DEF PACKET_COMMAND_MODE_SENSE_10 = 0x5a

DEF FD_HD_SECTOR_SIZE = 512
DEF FD_HD_SECTOR_SHIFT = 9

DEF CD_SECTOR_SIZE = 2048
DEF CD_SECTOR_SHIFT = 11

DEF ATA_ERROR_REG_MC  = 1 << 5
DEF ATA_ERROR_REG_MCR = 1 << 3


cdef extern from "Python.h":
    object PyBytes_FromStringAndSize(char *, Py_ssize_t)


# the variables shouldn't need to be in AtaDrive, as there are no mixed constellations. (MS/SL: HD/CD,CD/HD)
# instead, it's always ctrl0: HD/HD, ctrl1: CD/CD

cdef class AtaDrive:
    def __init__(self, AtaController ataController, unsigned char driveId, unsigned char driveType):
        self.ataController = ataController
        self.driveId = driveId
        self.driveType = driveType
        self.isLoaded = False
        self.isWriteProtected = True
        self.isLocked = False
        self.configSpace = ConfigSpace(512, self.ataController.ata.main)
        self.sectors = 0
        self.sectorShift = 0
        self.sectorSize = 0
        self.driveCode = BITMASK_WORD
        self.senseKey = self.senseAsc = 0
    cdef unsigned long int ChsToSector(self, unsigned int cylinder, unsigned char head, unsigned char sector) nogil:
        return (cylinder*HEADS+head)*SPT+(sector-1)
    cdef inline unsigned short readValue(self, unsigned char index):
        return self.configSpace.csReadValueUnsigned(index << 1, OP_SIZE_WORD)
    cdef inline void writeValue(self, unsigned char index, unsigned short value):
        self.configSpace.csWriteValue(index << 1, value, OP_SIZE_WORD)
    cdef void reset(self) nogil:
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
        if (self.driveType == ATA_DRIVE_TYPE_HD):
            self.sectorShift = FD_HD_SECTOR_SHIFT
            self.sectorSize = FD_HD_SECTOR_SIZE
            self.driveCode = 0x0
        elif (self.driveType == ATA_DRIVE_TYPE_CDROM):
            self.sectorShift = CD_SECTOR_SHIFT
            self.sectorSize = CD_SECTOR_SIZE
            self.driveCode = 0xeb14
        self.fp.seek(0, SEEK_END)
        self.sectors = self.fp.tell() >> self.sectorShift
        self.fp.seek(0)
        cylinders = self.sectors / (HEADS * SPT)
        if (cylinders > 16383):
            cylinders = 16383
        if (self.ataController.controllerId == 0 and self.driveId in (0, 1)):
            if (cylinders > 16383):
                self.writeValue(1, 16383) # word 1 ; cylinders
            else:
                self.writeValue(1, cylinders) # word 1 ; cylinders
            self.writeValue(3, HEADS) # word 3 ; heads
            self.writeValue(4, SPT << self.sectorShift) # word 4 ; spt * self.sectorSize
            self.writeValue(5, self.sectorSize) # hdd block size
            self.writeValue(6, SPT) # word 6 ; spt
            # 20, 21 commented out: no buffer
            #self.writeValue(20, 2) # type
            #self.writeValue(21, self.sectorSize) # increment in hdd block size
            if (self.driveId == 0):
                self.configSpace.csWrite(10 << 1, "NS1_325476_8 1", 13)
                self.configSpace.csWrite(27 << 1, "iHnriwhcesH_DD1_", 16)
            else:
                self.configSpace.csWrite(10 << 1, "NS1_325476_8 2", 13)
                self.configSpace.csWrite(27 << 1, "iHnriwhcesH_DD2_", 16)
            self.configSpace.csWrite(23 << 1, "WFRE0V10", 8)
            self.writeValue(59, 0x10)
            self.writeValue(53, 1)
            if (cylinders > 16383):
                self.writeValue(54, 16383) # word 54==1 ; cylinders
            else:
                self.writeValue(54, cylinders) # word 54==1 ; cylinders
            self.writeValue(55, HEADS) # word 55==3 ; heads
            self.writeValue(56, SPT) # word 56==6 ; spt
            self.writeValue(82, 0x4000)
            self.writeValue(83, 0x4400) # supports lba48
            self.writeValue(84, 0x4000)
            self.writeValue(85, 0x4000)
            self.writeValue(86, 0x0400) # supports lba48
            self.writeValue(87, 0x4000)
            self.writeValue(117, 0)
            self.writeValue(118, 0x100)
            self.writeValue(119, 0x4000)
            self.writeValue(120, 0x4000)
            if (not self.driveId):
                self.writeValue(93, (1 << 12)) # is master drive
            self.writeValue(57, <unsigned short>self.sectors) # total number of addressable blocks.
            self.writeValue(58, <unsigned short>(self.sectors>>16)) # total number of addressable blocks.
            self.writeValue(60, <unsigned short>self.sectors) # total number of addressable blocks.
            self.writeValue(61, <unsigned short>(self.sectors>>16)) # total number of addressable blocks.
            self.writeValue(47, 0x8010)
            self.writeValue(59, 0x110)
            self.configSpace.csWriteValue(100 << 1, self.sectors, OP_SIZE_QWORD) # total number of addressable blocks.
        self.writeValue(48, 1) # supports dword access
        self.writeValue(49, ((1 << 9) | (1 << 8))) # supports lba
        self.writeValue(50, 0x4000)
        self.writeValue(62, 0x480)
        self.writeValue(63, 1)
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
                self.ataController.ata.pciDevice.setData(0x40, 0x8000, OP_SIZE_WORD)
            else:
                (<Cmos>self.ataController.ata.main.platform.cmos).writeValue(CMOS_HD1_CONTROL_BYTE, 0x80, OP_SIZE_BYTE) # hardcoded
                self.ataController.ata.pciDevice.setData(0x42, 0x8000, OP_SIZE_WORD)
        else:
            self.writeValue(0, 0x85c0) # word 0 ; atapi; removable drive
            self.writeValue(82, 0x4010) # supports packet
            self.writeValue(85, 0x4010) # supports packet
            self.writeValue(125, CD_SECTOR_SIZE) # supports packet
    cdef bytes readBytes(self, unsigned long int offset, unsigned int size):
        cdef bytes data
        cdef unsigned long int oldPos
        oldPos = self.fp.tell()
        self.fp.seek(offset)
        data = self.fp.read(size)
        if (len(data) < size): # image is too short.
            data += bytes(size-len(data))
        self.fp.seek(oldPos)
        return data
    cdef inline bytes readSectors(self, unsigned long int sector, unsigned int count): # count in sectors
        return self.readBytes(sector << self.sectorShift, count << self.sectorShift)
    cdef void writeBytes(self, unsigned long int offset, unsigned int size, bytes data):
        cdef unsigned long int oldPos
        if (self.driveType == ATA_DRIVE_TYPE_CDROM):
            self.ataController.ata.main.notice("AtaDrive::writeBytes: tried to write to optical drive!")
            return
        elif (self.isWriteProtected):
            self.ataController.ata.main.notice("AtaDrive::writeBytes: isWriteProtected!")
            return
        if (len(data) < size): # data is too short.
            data += bytes(size-len(data))
        oldPos = self.fp.tell()
        self.fp.seek(offset)
        retData = self.fp.write(data)
        self.fp.seek(oldPos)
        self.fp.flush()
    cdef inline void writeSectors(self, unsigned long int sector, unsigned int count, bytes data):
        self.writeBytes(sector << self.sectorShift, count << self.sectorShift, data)
    cdef void run(self) nogil:
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
            self.irq = 0
            driveType = ATA_DRIVE_TYPE_NONE
        self.driveId = 0
        self.drive = (AtaDrive(self, 0, driveType), AtaDrive(self, 1, driveType))
        self.result = self.data = b''
        self.indexPulse = self.indexPulseCount = 0
    cdef void setSignature(self, unsigned char driveId):
        cdef AtaDrive drive
        drive = self.drive[driveId]
        self.head = self.multipleSectors = 0
        self.sector = self.sectorCount = self.sectorCountByte = 1
        if (not drive.driveCode):
            self.driveId = 0
        self.cylinder = drive.driveCode
        IF COMP_DEBUG:
            self.ata.main.notice("AtaController::setSignature: cylinder: {0:#06x}", self.cylinder)
    cdef void reset(self, unsigned char swReset):
        cdef AtaDrive drive
        self.drq = self.err = self.useLBA = self.useLBA48 = self.HOB = False
        self.seekComplete = self.irqEnabled = True
        self.cmd = self.features = 0
        self.errorRegister = 1
        self.sectorCountFlipFlop = self.sectorHighFlipFlop = self.sectorMiddleFlipFlop = self.sectorLowFlipFlop = False
        if (self.irq):
            (<Pic>self.ata.main.platform.pic).lowerIrq(self.irq)
        if (not swReset):
            self.doReset = self.driveBusy = self.resetInProgress = False
            self.driveReady = True
        else:
            self.driveReady = False
            self.driveBusy = self.resetInProgress = True
        self.busmasterCommand = self.busmasterStatus = self.busmasterAddress = 0
        #for drive in self.drive: # unused
        #    drive.reset()
    cdef inline void LbaToCHS(self) nogil:
        self.cylinder = self.lba / (HEADS*SPT)
        self.head = (self.lba / SPT) % HEADS
        self.sector = (self.lba % SPT) + 1
        self.sectorCountByte = <unsigned char>self.sectorCount
    cdef void convertToLBA28(self) nogil:
        #if (self.useLBA and self.useLBA48):
        if (self.useLBA):
        #if (self.useLBA and not self.useLBA48):
            self.sectorCount >>= 8
            self.lba >>= 24
            self.lba = (self.lba & 0xffffff) | (<unsigned long int>(self.head) << 24)
            if (not self.sectorCount):
                self.sectorCount = BITMASK_BYTE+1
            self.sectorCountFlipFlop = self.sectorHighFlipFlop = self.sectorMiddleFlipFlop = self.sectorLowFlipFlop = False
    cdef void raiseAtaIrq(self, unsigned char withDRQ, unsigned char doIRQ):
        if (self.irq and self.irqEnabled and doIRQ):
            IF COMP_DEBUG:
                if (self.ata.main.debugEnabled):
                    self.ata.main.notice("AtaController::raiseAtaIrq: raiseIrq")
            (<Pic>self.ata.main.platform.pic).raiseIrq(self.irq)
        if (withDRQ):
            self.drq = True
        #self.driveReady = self.seekComplete = not self.drq
        self.driveBusy = self.err = False
        if (self.cmd == COMMAND_EXECUTE_DRIVE_DIAGNOSTIC):
            self.errorRegister = 1
        else:
            self.errorRegister = 0
    cdef void lowerAtaIrq(self) nogil:
        self.driveReady = True
        self.drq = self.err = False
        self.errorRegister = 0
    cdef void abortCommand(self):
        self.errorCommand(0x04)
        if (self.irq):
            IF COMP_DEBUG:
                if (self.ata.main.debugEnabled):
                    self.ata.main.notice("AtaController::abortCommand: raiseIrq")
            (<Pic>self.ata.main.platform.pic).raiseIrq(self.irq)
    cdef void errorCommand(self, unsigned char errorRegister):
        cdef AtaDrive drive
        drive = self.drive[self.driveId]
        self.cmd = 0
        self.driveBusy = self.drq = False
        if (errorRegister == 0x02):
            self.seekComplete = False
        elif (errorRegister == 0x50):
            self.sectorCount = self.sectorCountByte = 3
            drive.senseKey = errorRegister>>4
            drive.senseAsc = 0x24
            if (self.irq):
                IF COMP_DEBUG:
                    if (self.ata.main.debugEnabled):
                        self.ata.main.notice("AtaController::errorCommand_1: raiseIrq")
                (<Pic>self.ata.main.platform.pic).raiseIrq(self.irq)
        elif (errorRegister == 0x20):
            self.sectorCount = self.sectorCountByte = 3
            drive.senseKey = errorRegister>>4
            drive.senseAsc = 0x3a
            if (self.irq):
                IF COMP_DEBUG:
                    if (self.ata.main.debugEnabled):
                        self.ata.main.notice("AtaController::errorCommand_1: raiseIrq")
                (<Pic>self.ata.main.platform.pic).raiseIrq(self.irq)
        self.driveReady = self.err = True
        self.errorRegister = errorRegister
        self.result = self.data = b''
        # TODO: HACK?: sectorCount/interrupt_reason
    cdef void nopCommand(self):
        cdef AtaDrive drive
        drive = self.drive[self.driveId]
        self.cmd = 0
        self.driveBusy = self.drq = self.err = False
        self.sectorCount = self.sectorCountByte = 3
        self.driveReady = True
        self.result = self.data = b''
        # TODO: HACK?: sectorCount/interrupt_reason
    cdef void handlePacket(self):
        cdef AtaDrive drive
        cdef unsigned char cmd, dataSize, msf, startingTrack, tocFormat, subQ, PC, pageCode
        cdef unsigned short allocLength
        drive = self.drive[self.driveId]
        cmd = self.data[0]
        self.result = b''
        #self.ata.main.notice("AtaController::handlePacket_0: self.data == {0:s}", repr(self.data))
        if (cmd == PACKET_COMMAND_TEST_UNIT_READY):
            if (drive.isLoaded):
                self.nopCommand()
                #self.result = bytes(8)
            else:
                self.errorCommand(0x20)
        elif (cmd == PACKET_COMMAND_REQUEST_SENSE):
            #self.ata.main.exitError("AtaController::handlePacket_3: test exit! self.data == {0:s}", repr(self.data))
            self.result = b'\xf0'
            self.result += (0).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
            self.result += (drive.senseKey).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
            self.result += bytes(4)
            self.result += (0xa).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
            self.result += bytes(4)
            if (not drive.isLoaded):
                self.result += b'\x3a\x00\x04\x01\x00\x00'
            else:
                self.result += (drive.senseAsc).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
                self.result += bytes(5)
        elif (cmd == PACKET_COMMAND_INQUIRY):
            dataSize = self.data[4]
            if (dataSize < 36):
                self.ata.main.notice("AtaController::handlePacket_6: allocation length is < 36! self.data == {0:s}", repr(self.data))
                return
            if (drive.driveType == ATA_DRIVE_TYPE_CDROM):
                self.result = drive.readValue(0).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
            else:
                self.result = bytes(2)
            self.result += b'\x00\x21'
            self.result += bytes([dataSize-5])
            self.result += bytes(dataSize-5)
        elif (cmd == PACKET_COMMAND_START_STOP_UNIT):
            pass
        elif (cmd == PACKET_COMMAND_READ_CAPACITY):
            if (drive.isLoaded):
                self.lba = drive.sectors - 1 # TODO: FIXME: 0-based?
                if (self.lba > BITMASK_DWORD):
                    self.lba = BITMASK_DWORD
                self.result = self.lba.to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result += (CD_SECTOR_SIZE).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                #self.sectorCount = self.sectorCountByte = 2
            else:
                self.errorCommand(0x20)
        elif (cmd in (PACKET_COMMAND_READ_10, PACKET_COMMAND_READ_12)):
            self.lba = int.from_bytes(self.data[2:2+OP_SIZE_DWORD], byteorder="big", signed=False)
            if (cmd == PACKET_COMMAND_READ_10):
                self.sectorCount = self.sectorCountByte = int.from_bytes(self.data[7:7+OP_SIZE_WORD], byteorder="big", signed=False)
            else:
                self.sectorCount = self.sectorCountByte = int.from_bytes(self.data[6:6+OP_SIZE_DWORD], byteorder="big", signed=False)
            self.result = drive.readSectors(self.lba, self.sectorCount)
        elif (cmd == PACKET_COMMAND_READ_SUBCHANNEL):
            if (drive.isLoaded):
                subQ = (self.data[2] >> 6) & 1
                allocLength = int.from_bytes(self.data[7:7+OP_SIZE_WORD], byteorder="big", signed=False)
                if (subQ):
                    self.ata.main.exitError("AtaController::handlePacket: subQ=={0:d}", subQ)
                    return
                self.result = bytes(4)
                self.result = self.result[0:min(len(self.result),allocLength)]
            else:
                self.errorCommand(0x20)
        elif (cmd == PACKET_COMMAND_READ_TOC):
            if (drive.isLoaded):
                msf = (self.data[1] >> 1) & 1
                startingTrack = self.data[6]
                allocLength = int.from_bytes(self.data[7:7+OP_SIZE_WORD], byteorder="big", signed=False)
                tocFormat = self.data[9] >> 6
                if ((startingTrack > 1 and startingTrack != 0xaa) or tocFormat):
                    self.ata.main.notice("AtaController::handlePacket: startingTrack=={0:d}; tocFormat=={1:d}", startingTrack, tocFormat)
                    self.errorCommand(0x50)
                    return
                self.result = (0x0012 if (startingTrack <= 1) else 0x000a).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
                self.result += (0x0101).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
                if (startingTrack <= 1):
                    self.result += (0x00140100).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                    self.result += (0x200 if (msf) else 0).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result += (0x0016aa00).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                if (msf):
                    self.result += (0).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
                    self.result += (<unsigned char>(((drive.sectors+150)//75)//60)).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
                    self.result += (<unsigned char>(((drive.sectors+150)//75)%60)).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
                    self.result += (<unsigned char>((drive.sectors+150)%75)).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
                else:
                    self.result += (drive.sectors).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result = self.result[0:min(len(self.result),allocLength)]
            else:
                self.errorCommand(0x20)
        elif (cmd in (PACKET_COMMAND_MODE_SENSE_6, PACKET_COMMAND_MODE_SENSE_10)):
            PC = (self.data[2] >> 6)
            pageCode = (self.data[2] & 0x3f)
            if (cmd == PACKET_COMMAND_MODE_SENSE_6):
                allocLength = int.from_bytes(self.data[7:7+OP_SIZE_WORD], byteorder="big", signed=False)
            else:
                allocLength = self.data[4]
            if (PC == 0 and pageCode == 0x2a):
                self.result = (0x001a).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
                if (drive.isLoaded):
                    self.result += (0x12).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
                else:
                    self.result += (0x70).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
                self.result += bytes(7)
                self.result += (0x2a120300).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result += (0x71602b00).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result += (0x0b000002).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result += (0x02000b00).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result += (0).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result = self.result[0:min(len(self.result),allocLength)]
            else:
                self.ata.main.notice("AtaController::handlePacket: PC=={0:d}; pageCode=={1:#04x}", PC, pageCode)
                self.errorCommand(0x50)
        else:
            self.ata.main.exitError("AtaController::handlePacket: cmd is unknown! cmd == {0:#04x}, self.data == {1:s}", cmd, repr(self.data))
            return
        if (not self.err):
            self.driveReady = self.seekComplete = self.drq = len(self.result) != 0
            self.sectorCount = self.sectorCountByte = (2 if (self.drq) else 3)
            #if (cmd not in (PACKET_COMMAND_READ_10, PACKET_COMMAND_READ_12)):
            #    self.cylinder = len(self.result)&0xfffe
            if (self.cylinder == BITMASK_WORD):
                self.cylinder = 0xfffe
            if (len(self.result) <= self.cylinder):
                self.cylinder = len(self.result)
            elif (self.cylinder & 1):
                self.cylinder &= 0xfffe
            self.raiseAtaIrq(False, True)
    cdef void handleBusmaster(self):
        cdef AtaDrive drive
        cdef unsigned int memBase, memSize, tempEntry, tempSectors
        cdef bytes tempResult
        cdef char *tempCharArray
        drive = self.drive[self.driveId]
        #if (self.irq): # TODO?
        #    (<Pic>self.ata.main.platform.pic).lowerIrq(self.irq)
        while (True):
            tempEntry = self.ata.main.mm.mmPhyReadValueUnsignedDword(self.busmasterAddress)
            memBase = tempEntry&0xfffffffe
            tempEntry = self.ata.main.mm.mmPhyReadValueUnsignedDword(self.busmasterAddress+4)
            memSize = tempEntry&0xfffe
            if (not memSize):
                memSize = SIZE_64KB
            self.busmasterAddress += 8
            if (self.busmasterCommand & ATA_BUSMASTER_CMD_READ_TO_MEM):
                IF COMP_DEBUG:
                    self.ata.main.notice("AtaController::handleBusmaster: test1: self.lba: {0:d}; self.sectorCount: {1:d}, memBase: {2:#010x}, memSize: {3:d}, len(self.result): {4:d}, self.result: {5:s}", self.lba, self.sectorCount, memBase, memSize, len(self.result), repr(self.result))
                self.ata.main.mm.mmPhyWrite(memBase, self.result[:memSize], memSize)
                self.result = self.result[memSize:]
            else:
                tempCharArray = self.ata.main.mm.mmPhyRead(memBase, memSize)
                tempResult = PyBytes_FromStringAndSize( tempCharArray, <Py_ssize_t>memSize)
                IF COMP_DEBUG:
                    self.ata.main.notice("AtaController::handleBusmaster: test2: self.lba: {0:d}; self.sectorCount: {1:d}, memBase: {2:#010x}, memSize: {3:d}, len(tempResult): {4:d}, tempResult: {5:s}", self.lba, self.sectorCount, memBase, memSize, len(tempResult), repr(tempResult))
                drive.writeBytes(self.lba << drive.sectorShift, memSize, tempResult)
            tempSectors = memSize >> drive.sectorShift
            if (self.sectorCount > 0):
                self.lba += tempSectors
                if (tempSectors > self.sectorCount):
                    IF COMP_DEBUG:
                        self.ata.main.notice("AtaController::handleBusmaster: TODO?: tempSectors > self.sectorCount; tempSectors: {0:d}; self.sectorCount: {1:d}", tempSectors, self.sectorCount)
                    self.result = bytes()
                    self.sectorCount = 0
                else:
                    self.sectorCount -= tempSectors
            if ((self.busmasterCommand & ATA_BUSMASTER_CMD_READ_TO_MEM) and (len(self.result)!=0)!=(self.sectorCount!=0)):
                break
            elif (tempEntry & BITMASKS_80[OP_SIZE_DWORD] or not self.sectorCount):
                break
        if ((self.busmasterCommand & ATA_BUSMASTER_CMD_READ_TO_MEM) and (len(self.result)!=0)!=(self.sectorCount!=0)):
            self.busmasterStatus &= ~1
            self.busmasterStatus |= 2
        else:
            if (tempEntry & BITMASKS_80[OP_SIZE_DWORD]):
                self.busmasterStatus &= ~1
            self.busmasterStatus |= 4
            self.raiseAtaIrq(False, True)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef AtaDrive drive
        cdef unsigned char isBusmaster
        cdef unsigned int ret = 0
        drive = self.drive[self.driveId]
        isBusmaster = self.ata.isBusmaster(ioPortAddr)
        if (not isBusmaster and ioPortAddr == 0x0): # data port
            if (not self.drq):
                ret = BITMASK_DWORD
                IF COMP_DEBUG:
                    self.ata.main.notice("AtaController::inPort_1: not self.drq, returning BITMASK_DWORD; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
                return ret
            if (len(self.result) < dataSize):
                ret = BITMASK_DWORD
                IF COMP_DEBUG:
                    self.ata.main.notice("AtaController::inPort_1: len(self.result) < dataSize; data port is empty, returning BITMASK_DWORD; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
                return ret
            ret = int.from_bytes(self.result[0:dataSize], byteorder="little", signed=False)
            self.result = self.result[dataSize:]
            #self.ata.main.notice("AtaController::inPort_1.1: cmd=={0:#04x}; len-result: {1:d}", self.cmd, len(self.result))
            self.driveReady = self.seekComplete = True
            self.drq = len(self.result) != 0
            if (self.cmd == COMMAND_PACKET):
                #self.driveReady = self.seekComplete = self.drq = len(self.result) != 0
                #self.driveReady = self.seekComplete = True
                #self.drq = len(self.result) != 0
                self.sectorCount = self.sectorCountByte = (2 if (self.drq) else 3)
                if (self.drq):
                    self.cylinder = len(self.result)&0xfffe
            elif (not (len(self.result) % drive.sectorSize)):
                self.lba += 1 # TODO
                self.sectorCount -= 1
                self.LbaToCHS()
                #self.drq = self.sectorCount != 0
                #self.driveReady = self.seekComplete = True
                #self.drq = len(self.result) != 0
                #self.driveReady = self.seekComplete = not self.drq
            self.raiseAtaIrq(False, True)
            return ret
        elif (dataSize == OP_SIZE_BYTE):
            if (isBusmaster):
                ioPortAddr -= self.ata.pciDevice.getData(PCI_BASE_ADDRESS_4, OP_SIZE_DWORD) & 0xfffc
                ioPortAddr &= 0x7
                if (ioPortAddr == 0x0):
                    return (self.busmasterCommand & 0x9)
                elif (ioPortAddr == 0x2):
                    return (self.busmasterStatus & 0x67)
                elif (ioPortAddr == 0x4):
                    return (self.busmasterAddress & 0xff)
                elif (ioPortAddr == 0x5):
                    return ((self.busmasterAddress >> 8) & 0xff)
                elif (ioPortAddr == 0x6):
                    return ((self.busmasterAddress >> 16) & 0xff)
                elif (ioPortAddr == 0x7):
                    return ((self.busmasterAddress >> 24) & 0xff)
                else:
                    IF COMP_DEBUG:
                        self.ata.main.notice("AtaController::inPort: read from reserved busmaster port; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
            elif (ioPortAddr in (0x1, 0x2, 0x3, 0x4, 0x5)):
                if ((<AtaDrive>(self.drive[0])).isLoaded or (<AtaDrive>(self.drive[1])).isLoaded):
                    if (ioPortAddr == 0x1):
                        return self.errorRegister
                    elif (ioPortAddr == 0x2):
                        #if (self.cmd == COMMAND_PACKET and not len(self.result)):
                        #    self.sectorCount = 3 # TODO: HACK?
                        #elif (self.useLBA):
                        #    if (self.HOB and self.useLBA48):
                        #        return ((self.sectorCount & 0xff00) >> 8)
                        #    return (self.sectorCount & 0x00ff)
                        #ret = <unsigned char>self.sectorCount
                        ret = <unsigned char>self.sectorCountByte
                    elif (ioPortAddr == 0x3):
                        #if (self.useLBA):
                        #    if (self.HOB and self.useLBA48):
                        #        return ((self.lba & 0x0000ff000000) >> 24)
                        #    return (self.lba & 0x0000000000ff)
                        ret = <unsigned char>self.sector
                    elif (ioPortAddr == 0x4):
                        #if (self.cmd == COMMAND_PACKET and len(self.result) <= BITMASK_WORD):
                        #    self.cylinder = len(self.result) # return length
                        #elif (self.useLBA):
                        #    if (self.HOB and self.useLBA48):
                        #        return ((self.lba & 0x00ff00000000) >> 32)
                        #    return ((self.lba & 0x00000000ff00) >> 8)
                        ret = <unsigned char>self.cylinder
                    elif (ioPortAddr == 0x5):
                        #if (self.cmd == COMMAND_PACKET and len(self.result) <= BITMASK_WORD):
                        #    self.cylinder = len(self.result) # return length
                        #elif (self.useLBA):
                        #    if (self.HOB and self.useLBA48):
                        #        return ((self.lba & 0xff0000000000) >> 40)
                        #    return ((self.lba & 0x000000ff0000) >> 16)
                        ret = <unsigned char>(self.cylinder >> 8)
            elif (ioPortAddr == 0x6):
                #ret = (0xa0) | (self.useLBA << 6) | (self.driveId << 4) | (((self.lba >> 24) if (self.useLBA) else self.head) & 0xf)
                ret = (0xa0) | (self.useLBA << 6) | (self.driveId << 4) | (self.head & 0xf)
            elif (ioPortAddr == 0x7 or ioPortAddr == 0x1fe or ioPortAddr == 0x206):
                if (drive.isLoaded):
                #IF 1:
                    ret = (self.driveBusy << 7) | (self.driveReady << 6) | (self.seekComplete << 4) | (self.drq << 3) | (self.indexPulse << 1) | (self.err)
                    self.indexPulseCount += 1
                    self.indexPulse = False
                    if (self.indexPulseCount >= 10): # stolen from bochs. thanks. :-)
                        self.indexPulse = True
                        self.indexPulseCount = 0
                else: # TODO: HACK: this circumvents the bochs bios 'IDE time out' which takes too long.
                    ret = 0
                    #ret = 0x41
                    #ret = 0x1
                    #ret = 0x81
                #ELSE:
                #    #ret = 0x1
                #    ret = 0x41
                if (ioPortAddr == 0x7 and self.irq):
                    (<Pic>self.ata.main.platform.pic).lowerIrq(self.irq)
            elif (ioPortAddr == 0x1ff or ioPortAddr == 0x207):
                ret = BITMASK_BYTE
                IF COMP_DEBUG:
                    self.ata.main.notice("AtaController::inPort: what???; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
            else:
                self.ata.main.exitError("AtaController::inPort: TODO: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
        else:
            self.ata.main.exitError("AtaController::inPort: dataSize {0:d} not supported.", dataSize)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef AtaDrive drive
        cdef unsigned char prevReset, isBusmaster
        drive = self.drive[self.driveId]
        isBusmaster = self.ata.isBusmaster(ioPortAddr)
        if (not isBusmaster and ioPortAddr == 0x0): # data port
            self.data += (data).to_bytes(length=dataSize, byteorder="little", signed=False)
            if (self.cmd in (COMMAND_WRITE_LBA28, COMMAND_WRITE_LBA48, COMMAND_WRITE_MULTIPLE_LBA28, COMMAND_WRITE_MULTIPLE_LBA48)):
                if (not self.drq):
                    IF COMP_DEBUG:
                        self.ata.main.notice("AtaController::outPort_1: not self.drq, returning; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
                    return
                if (len(self.data) >= drive.sectorSize):
                    drive.writeSectors(self.lba, 1, self.data)
                    self.data = self.data[drive.sectorSize:]
                    self.lba += 1 # TODO
                    self.sectorCount -= 1
                    self.LbaToCHS()
                    self.drq = self.sectorCount != 0
                    self.raiseAtaIrq(False, True)
            elif (self.cmd == COMMAND_PACKET):
                IF COMP_DEBUG:
                    if (self.ata.main.debugEnabled):
                        self.ata.main.notice("AtaController::outPort_0: len(self.data) == {0:d}, self.data == {1:s}", len(self.data), repr(self.data))
                if (len(self.data) >= 12):
                    self.handlePacket()
                else:
                    self.lowerAtaIrq()
            else:
                self.ata.main.exitError("AtaController::outPort: unknown command 1: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}; cmd: {5:#04x}", self.controllerId, self.driveId, ioPortAddr, data, dataSize, self.cmd)
        elif (dataSize == OP_SIZE_BYTE):
            if (isBusmaster):
                ioPortAddr -= self.ata.pciDevice.getData(PCI_BASE_ADDRESS_4, OP_SIZE_DWORD) & 0xfffc
                ioPortAddr &= 0x7
                if (ioPortAddr == 0x0):
                    self.busmasterCommand = (data & 0x9)
                    self.busmasterStatus &= ~1
                    self.busmasterStatus |= (self.busmasterCommand & 1)
                    if (self.busmasterCommand & 0x1):
                        self.handleBusmaster()
                elif (ioPortAddr == 0x2):
                    self.busmasterStatus &= ~(0x40 | 0x20)
                    self.busmasterStatus |= (data & (0x40 | 0x20))
                    if (data & 0x4):
                        self.busmasterStatus &= ~0x4
                    if (data & 0x2):
                        self.busmasterStatus &= ~0x2
                elif (ioPortAddr == 0x4):
                    self.busmasterAddress &= 0xffffff00
                    self.busmasterAddress |= (data & 0xfc)
                elif (ioPortAddr == 0x5):
                    self.busmasterAddress &= 0xffff00ff
                    self.busmasterAddress |= (data << 8)
                elif (ioPortAddr == 0x6):
                    self.busmasterAddress &= 0xff00ffff
                    self.busmasterAddress |= (data << 16)
                elif (ioPortAddr == 0x7):
                    self.busmasterAddress &= 0x00ffffff
                    self.busmasterAddress |= (data << 24)
                else:
                    IF COMP_DEBUG:
                        self.ata.main.notice("AtaController::outPort: write to reserved busmaster port; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
            elif (ioPortAddr == 0x1):
                self.features = data
                if (data & 3):
                    IF COMP_DEBUG:
                        self.ata.main.notice("AtaController::outPort: overlapping packet and/or DMA is not supported yet: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
            elif (ioPortAddr == 0x2):
                #if (self.useLBA and self.useLBA48):
                IF 1:
                    if (not self.sectorCountFlipFlop):
                        self.sectorCount = (self.sectorCount & 0x00ff) | ((<unsigned char>data) << 8)
                    else:
                        self.sectorCount = (self.sectorCount & 0xff00) | (<unsigned char>data)
                    self.sectorCountFlipFlop = not self.sectorCountFlipFlop
                #else:
                #    self.sectorCount = (<unsigned char>data)
                self.sectorCountByte = (<unsigned char>data)
            elif (ioPortAddr == 0x3):
                #if (self.useLBA and self.useLBA48):
                IF 1:
                    if (not self.sectorLowFlipFlop):
                        self.lba = (self.lba & <unsigned long int>0xffff00ffffff) | (<unsigned long int>(<unsigned char>data) << 24)
                    else:
                        self.lba = (self.lba & <unsigned long int>0xffffffffff00) | (<unsigned char>data)
                    self.sectorLowFlipFlop = not self.sectorLowFlipFlop
                #else:
                #    self.lba = (self.lba & 0xffff00) | (<unsigned char>data)
                self.sector = (<unsigned char>data)
            elif (ioPortAddr == 0x4):
                #if (self.useLBA and self.useLBA48):
                IF 1:
                    if (not self.sectorMiddleFlipFlop):
                        self.lba = (self.lba & <unsigned long int>0xff00ffffffff) | (<unsigned long int>(<unsigned char>data) << 32)
                    else:
                        self.lba = (self.lba & <unsigned long int>0xffffffff00ff) | ((<unsigned char>data) << 8)
                    self.sectorMiddleFlipFlop = not self.sectorMiddleFlipFlop
                #else:
                #    self.lba = (self.lba & 0xff00ff) | ((<unsigned char>data) << 8)
                self.cylinder = (self.cylinder & 0xff00) | (<unsigned char>data)
            elif (ioPortAddr == 0x5):
                #if (self.useLBA and self.useLBA48):
                IF 1:
                    if (not self.sectorHighFlipFlop):
                        self.lba = (self.lba & <unsigned long int>0x00ffffffffff) | (<unsigned long int>(<unsigned char>data) << 40)
                    else:
                        self.lba = (self.lba & <unsigned long int>0xffffff00ffff) | ((<unsigned char>data) << 16)
                    self.sectorHighFlipFlop = not self.sectorHighFlipFlop
                #else:
                #    self.lba = (self.lba & 0x00ffff) | ((<unsigned char>data) << 16)
                self.cylinder = (self.cylinder & 0x00ff) | ((<unsigned char>data) << 8)
            elif (ioPortAddr == 0x6):
                self.driveId = ((data & SELECT_SLAVE_DRIVE) == SELECT_SLAVE_DRIVE)
                drive = self.drive[self.driveId]
                self.useLBA = ((data & USE_LBA) == USE_LBA)
                self.useLBA48 = ((data & USE_LBA28) != USE_LBA28)
                self.head = data & 0xf
                self.sectorCountFlipFlop = self.sectorHighFlipFlop = self.sectorMiddleFlipFlop = self.sectorLowFlipFlop = False
                self.cmd = 0
                if (self.useLBA and self.useLBA48):
                    IF COMP_DEBUG:
                        self.ata.main.notice("AtaController::outPort: TODO: lba48 isn't fully supported yet!")
                    #return
            elif (ioPortAddr == 0x7): # command port
                if (self.driveId and not drive.isLoaded):
                    IF COMP_DEBUG:
                        if (self.ata.main.debugEnabled):
                            self.ata.main.notice("AtaController::outPort: selected slave, but it's not present; return")
                    return
                if (self.irq):
                    (<Pic>self.ata.main.platform.pic).lowerIrq(self.irq)
                self.result = self.data = b''
                #self.driveReady = self.seekComplete = False # TODO: HACK
                if (not self.useLBA):
                    self.sectorCount = self.sectorCountByte
                    self.lba = drive.ChsToSector(self.cylinder, self.head, self.sector)
                    IF COMP_DEBUG:
                        if (self.ata.main.debugEnabled):
                            self.ata.main.notice("AtaController::outPort: test3: lba=={0:d}, cylinder=={1:d}, head=={2:d}, sector=={3:d}, sectorCount=={4:d}", self.lba, self.cylinder, self.head, self.sector, self.sectorCount)
                if (not self.sectorCount):
                    if (self.useLBA and self.useLBA48):
                        self.sectorCount = BITMASK_WORD+1
                    else:
                        self.sectorCount = BITMASK_BYTE+1
                if ((data & 0xf0) == COMMAND_RECALIBRATE):
                    data = COMMAND_RECALIBRATE
                self.cmd = data
                if (data == COMMAND_RESET):
                    if (self.controllerId == 1):
                        self.setSignature(self.driveId)
                        self.result = b'\x00\x01\x01'
                        self.result += (drive.driveCode).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
                        self.result += b'\x00'
                    else:
                        self.abortCommand()
                        return
                elif (data == COMMAND_RECALIBRATE):
                    if (not drive.isLoaded):
                        self.errorCommand(0x02)
                        return
                    self.cylinder = 0
                elif (data in (COMMAND_IDENTIFY_DEVICE, COMMAND_IDENTIFY_DEVICE_PACKET)):
                    if (not drive.isLoaded):
                        self.abortCommand()
                        return
                    if ((self.controllerId == 0 and data == COMMAND_IDENTIFY_DEVICE_PACKET) or (self.controllerId == 1 and data == COMMAND_IDENTIFY_DEVICE)):
                        if (self.controllerId == 1 and data == COMMAND_IDENTIFY_DEVICE):
                            self.setSignature(self.driveId)
                        self.abortCommand()
                        return
                    self.driveReady = True
                    self.result = drive.configSpace.csRead(0, 512)
                elif (data in (COMMAND_READ_LBA28, COMMAND_READ_LBA28_WITHOUT_RETRIES, COMMAND_READ_LBA48, COMMAND_READ_MULTIPLE_LBA28, COMMAND_READ_MULTIPLE_LBA48, COMMAND_READ_DMA, COMMAND_READ_DMA_EXT)):
                    if (data in (COMMAND_READ_LBA28, COMMAND_READ_LBA28_WITHOUT_RETRIES, COMMAND_READ_MULTIPLE_LBA28, COMMAND_READ_DMA)):
                        self.convertToLBA28()
                    if (data in (COMMAND_READ_MULTIPLE_LBA28, COMMAND_READ_MULTIPLE_LBA48)):
                        if (not self.multipleSectors):
                            self.abortCommand()
                            return
                    self.result = drive.readSectors(self.lba, self.sectorCount)
                elif (data in (COMMAND_VERIFY_SECTORS_LBA28, COMMAND_VERIFY_SECTORS_LBA28_NO_RETRY, COMMAND_VERIFY_SECTORS_LBA48)):
                    if (data in (COMMAND_VERIFY_SECTORS_LBA28, COMMAND_VERIFY_SECTORS_LBA28_NO_RETRY)):
                        self.convertToLBA28()
                    if (not drive.isLoaded or drive.driveType != ATA_DRIVE_TYPE_HD):
                        self.abortCommand()
                        return
                    self.driveReady = True
                elif (data in (COMMAND_WRITE_LBA28, COMMAND_WRITE_LBA48, COMMAND_WRITE_MULTIPLE_LBA28, COMMAND_WRITE_MULTIPLE_LBA48, COMMAND_WRITE_DMA, COMMAND_WRITE_DMA_EXT, COMMAND_WRITE_DMA_FUA_EXT)):
                    if (data in (COMMAND_WRITE_LBA28, COMMAND_WRITE_MULTIPLE_LBA28, COMMAND_WRITE_DMA)):
                        self.convertToLBA28()
                    if (data in (COMMAND_WRITE_MULTIPLE_LBA28, COMMAND_WRITE_MULTIPLE_LBA48)):
                        if (not self.multipleSectors):
                            self.abortCommand()
                            return
                elif (data == COMMAND_PACKET):
                    if (self.controllerId == 1):
                        if (self.features & 2):
                            self.abortCommand()
                            return
                        else:
                            self.sectorCount = self.sectorCountByte = 1
                    else:
                        self.abortCommand()
                        return
                elif (data == COMMAND_EXECUTE_DRIVE_DIAGNOSTIC):
                    self.setSignature(self.driveId)
                elif (data == COMMAND_INITIALIZE_DRIVE_PARAMETERS):
                    if (not drive.isLoaded or drive.driveType != ATA_DRIVE_TYPE_HD):
                        self.abortCommand()
                        return
                    if ((self.sectorCount != SPT) or (self.head and self.head != HEADS-1)):
                        self.abortCommand()
                        return
                    self.driveReady = True
                elif (data == COMMAND_SET_FEATURES):
                    if (self.features == 3):
                        if ((self.sectorCount >> 3) not in (0, 1)):
                            self.abortCommand()
                            return
                    elif (self.features not in (0x02, 0x82, 0xAA, 0x55, 0xCC, 0x66)):
                        self.abortCommand()
                        return
                    self.driveReady = self.seekComplete = True
                elif (data == COMMAND_SET_MULTIPLE_MODE):
                    if (not self.sectorCount or self.sectorCount > 16 or self.sectorCount&(self.sectorCount-1)):
                        self.abortCommand()
                        return
                    self.multipleSectors = self.sectorCount
                elif (data == COMMAND_MEDIA_LOCK):
                    if (not drive.isLoaded or drive.driveType != ATA_DRIVE_TYPE_HD):
                        self.abortCommand()
                        return
                    if (not drive.isLocked):
                        drive.isLocked = True
                        self.err = False
                    elif (not drive.filename or not access(drive.filename, F_OK | R_OK) or not samefile(drive.fp.fileno(), drive.filename)):
                        self.errorRegister |= (ATA_ERROR_REG_MC | ATA_ERROR_REG_MCR)
                        self.err = True
                elif (data == COMMAND_MEDIA_UNLOCK):
                    if (not drive.isLoaded or drive.driveType != ATA_DRIVE_TYPE_HD):
                        self.abortCommand()
                        return
                    if (not drive.filename or not access(drive.filename, F_OK | R_OK) or not samefile(drive.fp.fileno(), drive.filename)):
                        drive.loadDrive(drive.filename)
                        self.errorRegister |= (ATA_ERROR_REG_MC | ATA_ERROR_REG_MCR)
                        self.err = True
                    elif (drive.isLocked):
                        drive.isLocked = False
                        self.err = False
                elif (data == COMMAND_READ_NATIVE_MAX_ADDRESS):
                    if (not drive.isLoaded or drive.driveType != ATA_DRIVE_TYPE_HD or not self.useLBA):
                        self.abortCommand()
                        return
                    self.lba = drive.sectors
                    self.sector = self.lba & BITMASK_BYTE
                    self.cylinder = (self.lba >> 8) & BITMASK_WORD
                    self.head = (self.lba >> 24) & 0xf
                    self.driveReady = self.seekComplete = True
                elif (data == COMMAND_READ_NATIVE_MAX_ADDRESS_EXT):
                    if (not drive.isLoaded or drive.driveType != ATA_DRIVE_TYPE_HD or not self.useLBA):
                        self.abortCommand()
                        return
                    self.lba = drive.sectors
                    if (self.useLBA48):
                        self.sector = self.lba & BITMASK_BYTE
                        self.cylinder = (self.lba >> 8) & BITMASK_WORD
                    else:
                        self.sector = self.lba & BITMASK_BYTE
                        self.cylinder = (self.lba >> 8) & BITMASK_WORD
                        self.head = (self.lba >> 24) & 0xf
                    self.driveReady = self.seekComplete = True
                elif (data == COMMAND_SET_MAX_ADDRESS):
                    #if (not drive.isLoaded or drive.driveType != ATA_DRIVE_TYPE_HD or not self.useLBA):
                    IF 1:
                        self.abortCommand()
                        return
                elif (data == COMMAND_CHECK_POWER_MODE): # TODO?
                    #self.sectorCount = self.sectorCountByte = 0xff
                    #self.driveReady = True
                    IF 1:
                        self.abortCommand()
                        return
                else:
                    self.ata.main.exitError("AtaController::outPort: unknown command 2: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
                    return
                self.raiseAtaIrq(data not in (COMMAND_RECALIBRATE, COMMAND_EXECUTE_DRIVE_DIAGNOSTIC, COMMAND_INITIALIZE_DRIVE_PARAMETERS, COMMAND_RESET, COMMAND_SET_FEATURES, COMMAND_SET_MULTIPLE_MODE, COMMAND_VERIFY_SECTORS_LBA28, COMMAND_VERIFY_SECTORS_LBA28_NO_RETRY, COMMAND_VERIFY_SECTORS_LBA48, COMMAND_MEDIA_LOCK, COMMAND_MEDIA_UNLOCK, COMMAND_READ_DMA, COMMAND_READ_DMA_EXT, COMMAND_WRITE_DMA, COMMAND_WRITE_DMA_EXT, COMMAND_WRITE_DMA_FUA_EXT, COMMAND_READ_NATIVE_MAX_ADDRESS, COMMAND_READ_NATIVE_MAX_ADDRESS_EXT, COMMAND_CHECK_POWER_MODE), data not in (COMMAND_RESET, COMMAND_PACKET, COMMAND_READ_DMA, COMMAND_READ_DMA_EXT, COMMAND_WRITE_DMA, COMMAND_WRITE_DMA_EXT, COMMAND_WRITE_DMA_FUA_EXT, COMMAND_CHECK_POWER_MODE))
            elif (ioPortAddr == 0x1fe or ioPortAddr == 0x206):
                prevReset = self.doReset
                self.irqEnabled = ((data & CONTROL_REG_NIEN) != CONTROL_REG_NIEN)
                self.doReset = ((data & CONTROL_REG_SRST) == CONTROL_REG_SRST)
                self.HOB = ((data & CONTROL_REG_HOB) == CONTROL_REG_HOB)
                IF COMP_DEBUG:
                    if (self.ata.main.debugEnabled):
                        self.ata.main.notice("AtaController::outPort: test2: prevReset=={0:d}; doReset=={1:d}; resetInProgress=={2:d}; irqEnabled=={3:d}; HOB=={4:d}", prevReset, self.doReset, self.resetInProgress, self.irqEnabled, self.HOB)
                if (not prevReset and self.doReset):
                    self.reset(True)
                elif (self.resetInProgress and not self.doReset):
                    self.driveBusy = self.resetInProgress = False
                    self.driveReady = True
                    self.setSignature(self.driveId)
            else:
                self.ata.main.exitError("AtaController::outPort: TODO: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
        else:
            self.ata.main.exitError("AtaController::outPort: dataSize {0:d} not supported.", dataSize)
    cdef void run(self):
        if (self.controllerId == 0):
            if (self.ata.main.hdaFilename): (<AtaDrive>self.drive[0]).loadDrive(self.ata.main.hdaFilename)
            if (self.ata.main.hdbFilename): (<AtaDrive>self.drive[1]).loadDrive(self.ata.main.hdbFilename)
        elif (self.controllerId == 1):
            if (self.ata.main.cdrom1Filename): (<AtaDrive>self.drive[0]).loadDrive(self.ata.main.cdrom1Filename)
            if (self.ata.main.cdrom2Filename): (<AtaDrive>self.drive[1]).loadDrive(self.ata.main.cdrom2Filename)


cdef class Ata:
    def __init__(self, Hirnwichse main):
        self.main = main
        self.controller = (AtaController(self, 0), AtaController(self, 1))
        self.pciDevice = (<Pci>self.main.platform.pci).addDevice()
        self.pciDevice.setVendorDeviceId(PCI_VENDOR_ID_INTEL, 0x7010)
        self.pciDevice.setDeviceClass(PCI_CLASS_PATA)
        #self.pciDevice.setBarSize(0, 4) # TODO?
        #self.pciDevice.setBarSize(1, 4) # TODO?
        #self.pciDevice.setBarSize(2, 4) # TODO?
        #self.pciDevice.setBarSize(3, 4) # TODO?
        self.pciDevice.setBarSize(4, 4) # TODO?
        self.pciDevice.setData(PCI_COMMAND, 0x1, OP_SIZE_BYTE)
        self.pciDevice.setData(PCI_STATUS, 0x280, OP_SIZE_WORD)
        self.pciDevice.setData(PCI_PROG_IF, 0x80, OP_SIZE_BYTE)
        self.pciDevice.setData(PCI_INTERRUPT_LINE, 14, OP_SIZE_BYTE)
        self.pciDevice.setData(PCI_INTERRUPT_PIN, 1, OP_SIZE_BYTE)
        #self.pciDevice.setData(PCI_BASE_ADDRESS_0, 0x1f1, OP_SIZE_DWORD)
        #self.pciDevice.setData(PCI_BASE_ADDRESS_1, 0x3f5, OP_SIZE_DWORD)
        #self.pciDevice.setData(PCI_BASE_ADDRESS_2, 0x171, OP_SIZE_DWORD)
        #self.pciDevice.setData(PCI_BASE_ADDRESS_3, 0x375, OP_SIZE_DWORD)
        #self.pciDevice.setData(PCI_BASE_ADDRESS_4, 0xc001, OP_SIZE_DWORD)
        self.pciDevice.setData(PCI_BASE_ADDRESS_4, 0x1, OP_SIZE_DWORD)
    cdef void reset(self):
        cdef AtaController controller
        for controller in self.controller:
            controller.reset(False)
    cdef unsigned char isBusmaster(self, unsigned short ioPortAddr):
        cdef unsigned int temp
        temp = self.pciDevice.getData(PCI_BASE_ADDRESS_4, OP_SIZE_DWORD)
        if (temp == BITMASK_DWORD or not (temp&1)):
            return False
        temp = temp&0xfffc
        if (not temp):
            return False
        if (ioPortAddr >= temp and ioPortAddr < temp+16):
            return True
        return False
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char isBusmaster = 0
        cdef unsigned int ret = BITMASKS_FF[dataSize]
        isBusmaster = self.isBusmaster(ioPortAddr)
        #if (self.main.debugEnabled):
        #IF 1:
        IF COMP_DEBUG:
            if (ioPortAddr&0xf or isBusmaster or self.main.debugEnabled):
                #self.main.debug("Ata::inPort1: ioPortAddr: {0:#06x}; dataSize: {1:d}", ioPortAddr, dataSize)
                self.main.notice("Ata::inPort1: ioPortAddr: {0:#06x}; dataSize: {1:d}", ioPortAddr, dataSize)
        if (isBusmaster and dataSize != OP_SIZE_BYTE):
            if (dataSize == OP_SIZE_WORD):
                ret = self.inPort(ioPortAddr, OP_SIZE_BYTE)
                ret |= self.inPort(ioPortAddr+1, OP_SIZE_BYTE) << 8
                return ret
            elif (dataSize == OP_SIZE_DWORD):
                ret = self.inPort(ioPortAddr, OP_SIZE_WORD)
                ret |= self.inPort(ioPortAddr+2, OP_SIZE_WORD) << 16
                return ret
        elif (dataSize == OP_SIZE_WORD and (ioPortAddr&0xf)):
            ret = self.inPort(ioPortAddr, OP_SIZE_BYTE)
            ret |= self.inPort(ioPortAddr, OP_SIZE_BYTE) << 8
            #if (self.main.debugEnabled):
            #IF 1:
            IF COMP_DEBUG:
                #self.main.debug("Ata::inPort2: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#06x}", ioPortAddr, dataSize, ret)
                self.main.notice("Ata::inPort2: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#06x}", ioPortAddr, dataSize, ret)
            return ret
        elif (dataSize == OP_SIZE_DWORD and (ioPortAddr&0xf)):
            ret = self.inPort(ioPortAddr, OP_SIZE_WORD)
            ret |= self.inPort(ioPortAddr, OP_SIZE_WORD) << 16
            #if (self.main.debugEnabled):
            #IF 1:
            IF COMP_DEBUG:
                #self.main.debug("Ata::inPort3: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#010x}", ioPortAddr, dataSize, ret)
                self.main.notice("Ata::inPort3: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#010x}", ioPortAddr, dataSize, ret)
            return ret
        if (isBusmaster):
            if (not ((ioPortAddr-(self.pciDevice.getData(PCI_BASE_ADDRESS_4, OP_SIZE_DWORD) & 0xfffc)) & 0x8)):
                ret = (<AtaController>self.controller[0]).inPort(ioPortAddr, dataSize)
            else:
                ret = (<AtaController>self.controller[1]).inPort(ioPortAddr, dataSize)
        elif (ioPortAddr in ATA1_PORTS and len(self.controller) >= 1 and self.controller[0]):
            ret = (<AtaController>self.controller[0]).inPort(ioPortAddr-ATA1_BASE, dataSize)
        elif (ioPortAddr in ATA2_PORTS and len(self.controller) >= 2 and self.controller[1]):
            ret = (<AtaController>self.controller[1]).inPort(ioPortAddr-ATA2_BASE, dataSize)
        #elif (ioPortAddr in ATA3_PORTS and len(self.controller) >= 3 and self.controller[2]):
        #    ret = (<AtaController>self.controller[2]).inPort(ioPortAddr-ATA3_BASE, dataSize)
        #elif (ioPortAddr in ATA4_PORTS and len(self.controller) >= 4 and self.controller[3]):
        #    ret = (<AtaController>self.controller[3]).inPort(ioPortAddr-ATA4_BASE, dataSize)
        #if (self.main.debugEnabled):
        #IF 1:
        IF COMP_DEBUG:
            if (ioPortAddr&0xf or isBusmaster or self.main.debugEnabled):
                #self.main.debug("Ata::inPort4: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#04x}", ioPortAddr, dataSize, ret)
                self.main.notice("Ata::inPort4: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#04x}", ioPortAddr, dataSize, ret)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef unsigned char isBusmaster = 0
        isBusmaster = self.isBusmaster(ioPortAddr)
        #if (self.main.debugEnabled):
        #IF 1:
        IF COMP_DEBUG:
            if (ioPortAddr&0xf or isBusmaster or self.main.debugEnabled):
                #self.main.debug("Ata::outPort: ioPortAddr: {0:#06x}; data: {1:#04x}; dataSize: {2:d}", ioPortAddr, data, dataSize)
                self.main.notice("Ata::outPort: ioPortAddr: {0:#06x}; data: {1:#04x}; dataSize: {2:d}", ioPortAddr, data, dataSize)
        if (isBusmaster and dataSize != OP_SIZE_BYTE):
            if (dataSize == OP_SIZE_WORD):
                self.outPort(ioPortAddr, <unsigned char>data, OP_SIZE_BYTE)
                self.outPort(ioPortAddr+1, <unsigned char>(data >> 8), OP_SIZE_BYTE)
                return
            elif (dataSize == OP_SIZE_DWORD):
                self.outPort(ioPortAddr, <unsigned short>data, OP_SIZE_WORD)
                self.outPort(ioPortAddr+2, <unsigned short>(data >> 16), OP_SIZE_WORD)
                return
        elif (dataSize == OP_SIZE_WORD and (ioPortAddr&0xf)):
            self.outPort(ioPortAddr, <unsigned char>data, OP_SIZE_BYTE)
            self.outPort(ioPortAddr, <unsigned char>(data >> 8), OP_SIZE_BYTE)
            return
        elif (dataSize == OP_SIZE_DWORD and (ioPortAddr&0xf)):
            self.outPort(ioPortAddr, <unsigned short>data, OP_SIZE_WORD)
            self.outPort(ioPortAddr, <unsigned short>(data >> 16), OP_SIZE_WORD)
            return
        if (isBusmaster):
            if (not ((ioPortAddr-(self.pciDevice.getData(PCI_BASE_ADDRESS_4, OP_SIZE_DWORD) & 0xfffc)) & 0x8)):
                (<AtaController>self.controller[0]).outPort(ioPortAddr, data, dataSize)
            else:
                (<AtaController>self.controller[1]).outPort(ioPortAddr, data, dataSize)
        elif (ioPortAddr in ATA1_PORTS and len(self.controller) >= 1 and self.controller[0]):
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


