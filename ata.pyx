
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

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
DEF COMMAND_SET_MULTIPLE_MODE = 0xc6
DEF COMMAND_SET_FEATURES = 0xef

DEF COMMAND_IDENTIFY_DEVICE = 0xec
DEF COMMAND_IDENTIFY_DEVICE_PACKET = 0xa1

DEF COMMAND_MEDIA_LOCK = 0xde
DEF COMMAND_MEDIA_UNLOCK = 0xdf

DEF COMMAND_IDLE_IMMEDIATE = 0xe1
DEF COMMAND_CHECK_POWER_MODE = 0xe5
DEF COMMAND_FLUSH_CACHE = 0xe7

DEF COMMAND_SECURITY_FREEZE_LOCK = 0xf5

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
DEF PACKET_COMMAND_MECHANISM_STATUS = 0xbd
DEF PACKET_COMMAND_READ_CD = 0xbe

DEF FD_HD_SECTOR_SIZE = 512
DEF FD_HD_SECTOR_SHIFT = 9

DEF CD_SECTOR_SIZE = 2048
DEF CD_SECTOR_SHIFT = 11

DEF ATA_ERROR_REG_MC  = 1 << 5
DEF ATA_ERROR_REG_MCR = 1 << 3


cdef extern from "Python.h":
    bytes PyBytes_FromStringAndSize(char *, Py_ssize_t)


# the variables shouldn't need to be in AtaDrive, as there are no mixed constellations. (MS/SL: HD/CD,CD/HD)
# instead, it's always ctrl0: HD/HD, ctrl1: CD/CD

cdef class AtaDrive:
    def __init__(self, AtaController ataController, uint8_t driveId, uint8_t driveType):
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
    cdef uint64_t ChsToSector(self, uint32_t cylinder, uint8_t head, uint8_t sector) nogil:
        return (cylinder*HEADS+head)*SPT+(sector-1)
    cdef inline void writeValue(self, uint8_t index, uint16_t value) nogil:
        self.configSpace.csWriteValueWord(index << 1, value)
    cdef void reset(self) nogil:
        pass
    cdef void loadDrive(self, bytes filename):
        cdef uint8_t cmosDiskType, translateReg, translateValue, translateValueTemp
        cdef uint32_t cylinders
        if (not filename):
            self.ataController.ata.main.notice("HD%u: loadDrive: file isn't found/accessable.", (self.ataController.controllerId << 1)+self.driveId)
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
            self.ataController.ata.main.notice("HD%u: loadDrive: file isn't found/accessable. (filename: %s, access-cmd)", (self.ataController.controllerId << 1)+self.driveId, filename)
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
            self.writeValue(57, <uint16_t>self.sectors) # total number of addressable blocks.
            self.writeValue(58, <uint16_t>(self.sectors>>16)) # total number of addressable blocks.
            self.writeValue(60, <uint16_t>self.sectors) # total number of addressable blocks.
            self.writeValue(61, <uint16_t>(self.sectors>>16)) # total number of addressable blocks.
            self.writeValue(47, 0x8010)
            self.writeValue(59, 0x110)
            self.configSpace.csWriteValueQword(100 << 1, self.sectors) # total number of addressable blocks.
        self.writeValue(48, 1) # supports dword access
        self.writeValue(49, ((1 << 9) | (1 << 8))) # supports lba
        self.writeValue(50, 0x4000)
        self.writeValue(62, 0x480)
        self.writeValue(63, 0x7 | (self.ataController.mdmaMode << 8))
        self.writeValue(88, 0x3f | (self.ataController.udmaMode << 8))
        self.writeValue(64, 1)
        self.writeValue(65, 0xb4)
        self.writeValue(66, 0xb4)
        self.writeValue(67, 0x12c)
        self.writeValue(68, 0xb4)
        self.writeValue(53, 6)
        if (cylinders <= 1024): # hardcoded
        #if (cylinders <= 2048): # hardcoded
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
            #self.writeValue(0, 0xff80) # word 0 ; ata; fixed drive
            self.writeValue(0, 0x4000) # word 0 ; ata; fixed drive
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
                #self.ataController.ata.pciDevice.configSpace.csWriteValueWord(0x40, 0x8000)
            else:
                (<Cmos>self.ataController.ata.main.platform.cmos).writeValue(CMOS_HD1_CONTROL_BYTE, 0x80, OP_SIZE_BYTE) # hardcoded
                #self.ataController.ata.pciDevice.configSpace.csWriteValueWord(0x42, 0x8000)
        elif (self.ataController.controllerId == 1 and self.driveId in (0, 1)):
            #self.writeValue(0, 0x85c0) # word 0 ; atapi; removable drive
            #self.writeValue(0, 0x0580) # word 0 ; atapi; removable drive
            self.writeValue(0, 0x0580) # word 0 ; atapi; removable drive
            self.writeValue(82, 0x4010) # supports packet
            self.writeValue(85, 0x4010) # supports packet
            self.writeValue(125, CD_SECTOR_SIZE) # supports packet
    cdef bytes readBytes(self, uint64_t offset, uint32_t size):
        cdef bytes data
        cdef uint64_t oldPos
        oldPos = self.fp.tell()
        self.fp.seek(offset)
        data = self.fp.read(size)
        if (len(data) < size): # image is too short.
            data += bytes(size-len(data))
        self.fp.seek(oldPos)
        return data
    cdef inline bytes readSectors(self, uint64_t sector, uint32_t count): # count in sectors
        return self.readBytes(sector << self.sectorShift, count << self.sectorShift)
    cdef void writeBytes(self, uint64_t offset, uint32_t size, bytes data):
        cdef uint64_t oldPos
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
    cdef inline void writeSectors(self, uint64_t sector, uint32_t count, bytes data):
        self.writeBytes(sector << self.sectorShift, count << self.sectorShift, data)
    cdef void run(self) nogil:
        pass


cdef class AtaController:
    def __init__(self, Ata ata, uint8_t controllerId):
        cdef AtaDrive drive0, drive1
        cdef uint8_t driveType # HACK
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
        drive0 = AtaDrive(self, 0, driveType)
        self.drive[0] = <PyObject*>drive0
        drive1 = AtaDrive(self, 1, driveType)
        self.drive[1] = <PyObject*>drive1
        self.result = self.data = b''
        self.indexPulse = self.indexPulseCount = 0
        Py_INCREF(drive0)
        Py_INCREF(drive1)
    cdef void setSignature(self, uint8_t driveId) nogil:
        self.head = self.multipleSectors = 0
        self.sector = self.sectorCount = self.sectorCountByte = 1
        if (not (<AtaDrive>self.drive[driveId]).driveCode):
            self.driveId = 0
        self.cylinder = (<AtaDrive>self.drive[driveId]).driveCode
        IF COMP_DEBUG:
            self.ata.main.notice("AtaController::setSignature: cylinder: 0x%04x", self.cylinder)
    cdef void reset(self, uint8_t swReset) nogil:
        #cdef AtaDrive drive
        self.drq = self.err = self.useLBA = self.useLBA48 = self.HOB = False
        self.seekComplete = self.irqEnabled = True
        self.cmd = self.features = self.mdmaMode = self.udmaMode = 0
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
        self.sectorCountByte = <uint8_t>self.sectorCount
    cdef void convertToLBA28(self) nogil:
        #if (self.useLBA and self.useLBA48):
        if (self.useLBA):
        #if (self.useLBA and not self.useLBA48):
            self.sectorCount >>= 8
            self.lba >>= 24
            self.lba = (self.lba & 0xffffff) | (<uint64_t>(self.head) << 24)
            if (not self.sectorCount):
                self.sectorCount = BITMASK_BYTE+1
            self.sectorCountFlipFlop = self.sectorHighFlipFlop = self.sectorMiddleFlipFlop = self.sectorLowFlipFlop = False
    cdef void raiseAtaIrq(self, uint8_t withDRQ, uint8_t doIRQ) nogil:
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
    cdef void abortCommand(self) nogil:
        self.errorCommand(0x04)
        if (self.irq):
            IF COMP_DEBUG:
                if (self.ata.main.debugEnabled):
                    self.ata.main.notice("AtaController::abortCommand: raiseIrq")
            (<Pic>self.ata.main.platform.pic).raiseIrq(self.irq)
    cdef void errorCommand(self, uint8_t errorRegister) nogil:
        self.cmd = 0
        self.driveBusy = self.drq = False
        if (errorRegister == 0x02):
            self.seekComplete = False
        elif (errorRegister == 0x50):
            self.sectorCount = self.sectorCountByte = 3
            (<AtaDrive>self.drive[self.driveId]).senseKey = errorRegister>>4
            (<AtaDrive>self.drive[self.driveId]).senseAsc = 0x24
            if (self.irq):
                IF COMP_DEBUG:
                    if (self.ata.main.debugEnabled):
                        self.ata.main.notice("AtaController::errorCommand_1: raiseIrq")
                (<Pic>self.ata.main.platform.pic).raiseIrq(self.irq)
        elif (errorRegister == 0x20):
            self.sectorCount = self.sectorCountByte = 3
            (<AtaDrive>self.drive[self.driveId]).senseKey = errorRegister>>4
            (<AtaDrive>self.drive[self.driveId]).senseAsc = 0x3a
            if (self.irq):
                IF COMP_DEBUG:
                    if (self.ata.main.debugEnabled):
                        self.ata.main.notice("AtaController::errorCommand_1: raiseIrq")
                (<Pic>self.ata.main.platform.pic).raiseIrq(self.irq)
        self.driveReady = self.err = True
        self.errorRegister = errorRegister
        with gil:
            self.result = self.data = b''
        # TODO: HACK?: sectorCount/interrupt_reason
    cdef void nopCommand(self) nogil:
        self.cmd = 0
        self.driveBusy = self.drq = self.err = False
        self.sectorCount = self.sectorCountByte = 3
        self.driveReady = True
        self.errorRegister = 0
        with gil:
            self.result = self.data = b''
        # TODO: HACK?: sectorCount/interrupt_reason
        if (self.irq):
            (<Pic>self.ata.main.platform.pic).raiseIrq(self.irq)
    cdef void handlePacket(self):
        cdef AtaDrive drive
        cdef uint8_t cmd, dataSize, msf, startingTrack, tocFormat, subQ, PC, pageCode, transferReq
        cdef uint16_t allocLength
        drive = <AtaDrive>self.drive[self.driveId]
        cmd = self.data[0]
        self.result = b''
        #self.ata.main.notice("AtaController::handlePacket_0: self.data == %s", repr(self.data))
        if (cmd == PACKET_COMMAND_TEST_UNIT_READY):
            if (drive.isLoaded):
                #self.result = bytes(8)
                self.nopCommand()
                return
            else:
                self.errorCommand(0x20)
                return
        elif (cmd == PACKET_COMMAND_REQUEST_SENSE):
            #self.ata.main.exitError("AtaController::handlePacket_3: test exit! self.data == %s", repr(self.data))
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
                #self.ata.main.notice("AtaController::handlePacket_6: allocation length is < 36! self.data == %s", repr(self.data))
                return
            #if (drive.driveType == ATA_DRIVE_TYPE_CDROM):
            #    #self.result = drive.configSpace.csReadValueUnsigned(0, OP_SIZE_WORD).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
            #    self.result = (0x0580).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
            #else:
            #    #self.result = bytes(2)
            #    self.result = (0x4000).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
            self.result = drive.configSpace.csReadValueUnsigned(0, OP_SIZE_WORD).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
            self.result += b'\x00\x21'
            self.result += bytes([dataSize-5])
            self.result += bytes(3)
            self.result += b'HWEMU   '
            self.result += b'CD-ROM          '
            self.result += b'1.0 '
            if (dataSize > 36):
                self.result += bytes(dataSize-5-3-8-16-4)
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
        elif (cmd == PACKET_COMMAND_READ_CD):
            if (drive.isLoaded):
                self.lba = int.from_bytes(self.data[2:2+OP_SIZE_DWORD], byteorder="big", signed=False)
                self.sectorCount = self.sectorCountByte = int.from_bytes(self.data[6:6+3], byteorder="big", signed=False)
                transferReq = self.data[9]&0xf8
                #self.ata.main.notice("AtaController::handlePacket: READ_CD! cmd == 0x%02x, self.data == %s", cmd, <bytes>repr(self.data).encode())
                #self.ata.main.notice("AtaController::handlePacket: transferReq==%u, lba==%u, sectorCount==%u", transferReq, self.lba, self.sectorCount)
                if (not self.sectorCount or not transferReq):
                    self.nopCommand()
                    return
                else:
                    if (transferReq == 0xf8):
                        self.ata.main.exitError("AtaController::handlePacket: transferReq==%u", transferReq)
                        return
                    elif (transferReq != 0x10):
                        self.ata.main.notice("AtaController::handlePacket: transferReq==%u, unknown format", transferReq)
                        self.errorCommand(0x50)
                        return
                    self.result = drive.readSectors(self.lba, self.sectorCount)
            else:
                self.errorCommand(0x20)
                return
        elif (cmd in (PACKET_COMMAND_READ_10, PACKET_COMMAND_READ_12)):
            if (drive.isLoaded):
                self.lba = int.from_bytes(self.data[2:2+OP_SIZE_DWORD], byteorder="big", signed=False)
                if (cmd == PACKET_COMMAND_READ_10):
                    self.sectorCount = self.sectorCountByte = int.from_bytes(self.data[7:7+OP_SIZE_WORD], byteorder="big", signed=False)
                else:
                    self.sectorCount = self.sectorCountByte = int.from_bytes(self.data[6:6+OP_SIZE_DWORD], byteorder="big", signed=False)
                self.result = drive.readSectors(self.lba, self.sectorCount)
            else:
                self.errorCommand(0x20)
                return
        elif (cmd == PACKET_COMMAND_READ_SUBCHANNEL):
            if (drive.isLoaded):
                subQ = (self.data[2] >> 6) & 1
                allocLength = int.from_bytes(self.data[7:7+OP_SIZE_WORD], byteorder="big", signed=False)
                if (subQ):
                    self.ata.main.exitError("AtaController::handlePacket: subQ==%u", subQ)
                    return
                self.result = bytes(4)
                self.result = self.result[0:min(len(self.result),allocLength)]
            else:
                self.errorCommand(0x20)
                return
        elif (cmd == PACKET_COMMAND_READ_TOC):
            if (drive.isLoaded):
                msf = (self.data[1] >> 1) & 1
                startingTrack = self.data[6]
                allocLength = int.from_bytes(self.data[7:7+OP_SIZE_WORD], byteorder="big", signed=False)
                tocFormat = self.data[9] >> 6
                if ((startingTrack > 1 and startingTrack != 0xaa) or tocFormat):
                    self.ata.main.notice("AtaController::handlePacket: startingTrack==%u; tocFormat==%u", startingTrack, tocFormat)
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
                    self.result += (<uint8_t>(((drive.sectors+150)//75)//60)).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
                    self.result += (<uint8_t>(((drive.sectors+150)//75)%60)).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
                    self.result += (<uint8_t>((drive.sectors+150)%75)).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
                else:
                    self.result += (drive.sectors).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result = self.result[0:min(len(self.result),allocLength)]
            else:
                self.errorCommand(0x20)
                return
        elif (cmd in (PACKET_COMMAND_MODE_SENSE_6, PACKET_COMMAND_MODE_SENSE_10)):
            PC = (self.data[2] >> 6)
            pageCode = (self.data[2] & 0x3f)
            if (cmd == PACKET_COMMAND_MODE_SENSE_6):
                allocLength = int.from_bytes(self.data[7:7+OP_SIZE_WORD], byteorder="big", signed=False)
            else:
                allocLength = self.data[4]
            self.result = (0x001a).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
            if (drive.isLoaded):
                self.result += (0x12).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
            else:
                self.result += (0x70).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
            self.result += bytes(5)
            if (PC == 0 and pageCode == 0x01):
                self.result += (0x01060005).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result += bytes(4)
            elif (PC == 0 and pageCode == 0x2a):
                self.result += (0x2a120300).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result += (0x71602b00).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result += (0x0b000002).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result += (0x02000b00).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result += (0).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
                self.result = self.result[0:min(len(self.result),allocLength)]
            else:
                self.result = bytes()
                self.ata.main.notice("AtaController::handlePacket: PC==%u; pageCode==0x%02x", PC, pageCode)
                self.errorCommand(0x50)
                return
        elif (cmd == PACKET_COMMAND_MECHANISM_STATUS):
            #self.ata.main.exitError("AtaController::handlePacket_3: test exit! self.data == %s", repr(self.data))
            self.result = bytes(5)
            self.result += (1).to_bytes(length=OP_SIZE_BYTE, byteorder="big", signed=False)
            self.result += bytes(2)
        else:
            self.ata.main.exitError("AtaController::handlePacket: cmd is unknown! cmd == 0x%02x, self.data == %s", cmd, <bytes>repr(self.data).encode())
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
        cdef uint32_t memBase, memSize, tempEntry, tempSectors
        cdef bytes tempResult
        cdef char *tempCharArray
        #if (self.irq): # TODO?
        #    (<Pic>self.ata.main.platform.pic).lowerIrq(self.irq)
        while (True):
            tempEntry = self.ata.main.mm.mmPhyReadValueUnsignedDword(self.busmasterAddress)
            memBase = tempEntry&<uint32_t>0xfffffffe
            tempEntry = self.ata.main.mm.mmPhyReadValueUnsignedDword(self.busmasterAddress+4)
            memSize = tempEntry&0xfffe
            if (not memSize):
                memSize = SIZE_64KB
            self.busmasterAddress += 8
            if (self.busmasterCommand & ATA_BUSMASTER_CMD_READ_TO_MEM):
                IF COMP_DEBUG:
                    self.ata.main.notice("AtaController::handleBusmaster: test1: self.lba: %u; self.sectorCount: %u, memBase: 0x%08x, memSize: %u, len(self.result): %u, self.result: %s", self.lba, self.sectorCount, memBase, memSize, len(self.result), <bytes>repr(self.result).encode())
                self.ata.main.mm.mmPhyWrite(memBase, self.result[:memSize], memSize)
                self.result = self.result[memSize:]
            else:
                tempCharArray = self.ata.main.mm.mmPhyRead(memBase, memSize)
                tempResult = PyBytes_FromStringAndSize( tempCharArray, <Py_ssize_t>memSize)
                IF COMP_DEBUG:
                    self.ata.main.notice("AtaController::handleBusmaster: test2: self.lba: %u; self.sectorCount: %u, memBase: 0x%08x, memSize: %u, len(tempResult): %u, tempResult: %s", self.lba, self.sectorCount, memBase, memSize, len(tempResult), <bytes>repr(tempResult).encode())
                (<AtaDrive>self.drive[self.driveId]).writeBytes(self.lba << (<AtaDrive>self.drive[self.driveId]).sectorShift, memSize, tempResult)
            tempSectors = memSize >> (<AtaDrive>self.drive[self.driveId]).sectorShift
            if (self.sectorCount > 0):
                self.lba += tempSectors
                if (tempSectors > self.sectorCount):
                    IF COMP_DEBUG:
                        self.ata.main.notice("AtaController::handleBusmaster: TODO?: tempSectors > self.sectorCount; tempSectors: %u; self.sectorCount: %u", tempSectors, self.sectorCount)
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
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil:
        cdef uint8_t isBusmaster
        cdef uint32_t ret = 0, temp = 0
        isBusmaster = self.ata.isBusmaster(ioPortAddr)
        if (not isBusmaster and ioPortAddr == 0x0): # data port
            if (not self.drq):
                ret = BITMASK_DWORD
                IF COMP_DEBUG:
                    self.ata.main.notice("AtaController::inPort_1: not self.drq, returning BITMASK_DWORD; controllerId: %u; driveId: %u; ioPortAddr: 0x%04x; dataSize: %u", self.controllerId, self.driveId, ioPortAddr, dataSize)
                return ret
            with gil:
                temp = min(len(self.result), dataSize)
                if (temp > 0):
                    ret = int.from_bytes(self.result[0:dataSize]+bytes(dataSize-temp), byteorder="little", signed=False)
                    self.result = self.result[temp:]
                else:
                    ret = BITMASK_DWORD
                    self.result = bytes()
                self.drq = len(self.result) != 0
            #self.ata.main.notice("AtaController::inPort_1.1: cmd==0x%02x; len-result: %u", self.cmd, len(self.result))
            self.driveReady = self.seekComplete = True
            if (self.cmd == COMMAND_PACKET):
                #self.driveReady = self.seekComplete = self.drq = len(self.result) != 0
                #self.driveReady = self.seekComplete = True
                #self.drq = len(self.result) != 0
                self.sectorCount = self.sectorCountByte = (2 if (self.drq) else 3)
                if (self.drq):
                    with gil:
                        self.cylinder = len(self.result)&0xfffe
            else:
                with gil:
                    if (not (len(self.result) % (<AtaDrive>self.drive[self.driveId]).sectorSize)):
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
                        self.ata.main.notice("AtaController::inPort: read from reserved busmaster port; controllerId: %u; driveId: %u; ioPortAddr: 0x%04x; dataSize: %u", self.controllerId, self.driveId, ioPortAddr, dataSize)
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
                        #ret = <uint8_t>self.sectorCount
                        ret = <uint8_t>self.sectorCountByte
                    elif (ioPortAddr == 0x3):
                        #if (self.useLBA):
                        #    if (self.HOB and self.useLBA48):
                        #        return ((self.lba & 0x0000ff000000) >> 24)
                        #    return (self.lba & 0x0000000000ff)
                        ret = <uint8_t>self.sector
                    elif (ioPortAddr == 0x4):
                        #if (self.cmd == COMMAND_PACKET and len(self.result) <= BITMASK_WORD):
                        #    self.cylinder = len(self.result) # return length
                        #elif (self.useLBA):
                        #    if (self.HOB and self.useLBA48):
                        #        return ((self.lba & 0x00ff00000000) >> 32)
                        #    return ((self.lba & 0x00000000ff00) >> 8)
                        ret = <uint8_t>self.cylinder
                    elif (ioPortAddr == 0x5):
                        #if (self.cmd == COMMAND_PACKET and len(self.result) <= BITMASK_WORD):
                        #    self.cylinder = len(self.result) # return length
                        #elif (self.useLBA):
                        #    if (self.HOB and self.useLBA48):
                        #        return ((self.lba & 0xff0000000000) >> 40)
                        #    return ((self.lba & 0x000000ff0000) >> 16)
                        ret = <uint8_t>(self.cylinder >> 8)
            elif (ioPortAddr == 0x6):
                #ret = (0xa0) | (self.useLBA << 6) | (self.driveId << 4) | (((self.lba >> 24) if (self.useLBA) else self.head) & 0xf)
                ret = (0xa0) | (self.useLBA << 6) | (self.driveId << 4) | (self.head & 0xf)
            elif (ioPortAddr == 0x7 or ioPortAddr == 0x1fe or ioPortAddr == 0x206):
                if ((<AtaDrive>self.drive[self.driveId]).isLoaded):
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
                    self.ata.main.notice("AtaController::inPort: what???; controllerId: %u; driveId: %u; ioPortAddr: 0x%04x; dataSize: %u", self.controllerId, self.driveId, ioPortAddr, dataSize)
            else:
                self.ata.main.exitError("AtaController::inPort: TODO: controllerId: %u; driveId: %u; ioPortAddr: 0x%04x; dataSize: %u", self.controllerId, self.driveId, ioPortAddr, dataSize)
        else:
            self.ata.main.exitError("AtaController::inPort: dataSize %u not supported.", dataSize)
        return ret
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil:
        cdef uint8_t prevReset, isBusmaster
        isBusmaster = self.ata.isBusmaster(ioPortAddr)
        if (not isBusmaster and ioPortAddr == 0x0): # data port
            with gil:
                self.data += (data).to_bytes(length=dataSize, byteorder="little", signed=False)
            if (self.cmd in (COMMAND_WRITE_LBA28, COMMAND_WRITE_LBA48, COMMAND_WRITE_MULTIPLE_LBA28, COMMAND_WRITE_MULTIPLE_LBA48)):
                if (not self.drq):
                    IF COMP_DEBUG:
                        self.ata.main.notice("AtaController::outPort_1: not self.drq, returning; controllerId: %u; driveId: %u; ioPortAddr: 0x%04x; data: 0x%02x; dataSize: %u", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
                    return
                with gil:
                    if (len(self.data) >= (<AtaDrive>self.drive[self.driveId]).sectorSize):
                        (<AtaDrive>self.drive[self.driveId]).writeSectors(self.lba, 1, self.data)
                        self.data = self.data[(<AtaDrive>self.drive[self.driveId]).sectorSize:]
                        self.lba += 1 # TODO
                        self.sectorCount -= 1
                        self.LbaToCHS()
                        self.drq = self.sectorCount != 0
                        self.raiseAtaIrq(False, True)
            elif (self.cmd == COMMAND_PACKET):
                IF COMP_DEBUG:
                    if (self.ata.main.debugEnabled):
                        self.ata.main.notice("AtaController::outPort_0: len(self.data) == %u, self.data == %s", len(self.data), <bytes>repr(self.data).encode())
                with gil:
                    if (len(self.data) >= 12):
                        self.handlePacket()
                    else:
                        self.lowerAtaIrq()
            else:
                self.ata.main.exitError("AtaController::outPort: unknown command 1: controllerId: %u; driveId: %u; ioPortAddr: 0x%04x; data: 0x%02x; dataSize: %u; cmd: 0x%02x", self.controllerId, self.driveId, ioPortAddr, data, dataSize, self.cmd)
        elif (dataSize == OP_SIZE_BYTE):
            if (isBusmaster):
                ioPortAddr -= self.ata.pciDevice.getData(PCI_BASE_ADDRESS_4, OP_SIZE_DWORD) & 0xfffc
                ioPortAddr &= 0x7
                if (ioPortAddr == 0x0):
                    self.busmasterCommand = (data & 0x9)
                    self.busmasterStatus &= ~1
                    self.busmasterStatus |= (self.busmasterCommand & 1)
                    if (self.busmasterCommand & 0x1):
                        with gil:
                            self.handleBusmaster()
                elif (ioPortAddr == 0x2):
                    self.busmasterStatus &= ~(0x40 | 0x20)
                    self.busmasterStatus |= (data & (0x40 | 0x20))
                    if (data & 0x4):
                        self.busmasterStatus &= ~0x4
                    if (data & 0x2):
                        self.busmasterStatus &= ~0x2
                elif (ioPortAddr == 0x4):
                    self.busmasterAddress &= <uint32_t>0xffffff00
                    self.busmasterAddress |= (data & 0xfc)
                elif (ioPortAddr == 0x5):
                    self.busmasterAddress &= <uint32_t>0xffff00ff
                    self.busmasterAddress |= (data << 8)
                elif (ioPortAddr == 0x6):
                    self.busmasterAddress &= <uint32_t>0xff00ffff
                    self.busmasterAddress |= (data << 16)
                elif (ioPortAddr == 0x7):
                    self.busmasterAddress &= <uint32_t>0x00ffffff
                    self.busmasterAddress |= (data << 24)
                else:
                    IF COMP_DEBUG:
                        self.ata.main.notice("AtaController::outPort: write to reserved busmaster port; controllerId: %u; driveId: %u; ioPortAddr: 0x%04x; data: 0x%02x; dataSize: %u", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
            elif (ioPortAddr == 0x1):
                self.features = data
                if (data & 3):
                    IF COMP_DEBUG:
                        self.ata.main.notice("AtaController::outPort: overlapping packet and/or DMA is not supported yet: controllerId: %u; driveId: %u; ioPortAddr: 0x%04x; data: 0x%02x; dataSize: %u", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
            elif (ioPortAddr == 0x2):
                #if (self.useLBA and self.useLBA48):
                IF 1:
                    if (not self.sectorCountFlipFlop):
                        self.sectorCount = (self.sectorCount & 0x00ff) | ((<uint8_t>data) << 8)
                    else:
                        self.sectorCount = (self.sectorCount & 0xff00) | (<uint8_t>data)
                    self.sectorCountFlipFlop = not self.sectorCountFlipFlop
                #else:
                #    self.sectorCount = (<uint8_t>data)
                self.sectorCountByte = (<uint8_t>data)
            elif (ioPortAddr == 0x3):
                #if (self.useLBA and self.useLBA48):
                IF 1:
                    if (not self.sectorLowFlipFlop):
                        self.lba = (self.lba & <uint64_t>0xffff00ffffff) | (<uint64_t>(<uint8_t>data) << 24)
                    else:
                        self.lba = (self.lba & <uint64_t>0xffffffffff00) | (<uint8_t>data)
                    self.sectorLowFlipFlop = not self.sectorLowFlipFlop
                #else:
                #    self.lba = (self.lba & 0xffff00) | (<uint8_t>data)
                self.sector = (<uint8_t>data)
            elif (ioPortAddr == 0x4):
                #if (self.useLBA and self.useLBA48):
                IF 1:
                    if (not self.sectorMiddleFlipFlop):
                        self.lba = (self.lba & <uint64_t>0xff00ffffffff) | (<uint64_t>(<uint8_t>data) << 32)
                    else:
                        self.lba = (self.lba & <uint64_t>0xffffffff00ff) | ((<uint8_t>data) << 8)
                    self.sectorMiddleFlipFlop = not self.sectorMiddleFlipFlop
                #else:
                #    self.lba = (self.lba & 0xff00ff) | ((<uint8_t>data) << 8)
                self.cylinder = (self.cylinder & 0xff00) | (<uint8_t>data)
            elif (ioPortAddr == 0x5):
                #if (self.useLBA and self.useLBA48):
                IF 1:
                    if (not self.sectorHighFlipFlop):
                        self.lba = (self.lba & <uint64_t>0x00ffffffffff) | (<uint64_t>(<uint8_t>data) << 40)
                    else:
                        self.lba = (self.lba & <uint64_t>0xffffff00ffff) | ((<uint8_t>data) << 16)
                    self.sectorHighFlipFlop = not self.sectorHighFlipFlop
                #else:
                #    self.lba = (self.lba & 0x00ffff) | ((<uint8_t>data) << 16)
                self.cylinder = (self.cylinder & 0x00ff) | ((<uint8_t>data) << 8)
            elif (ioPortAddr == 0x6):
                self.driveId = ((data & SELECT_SLAVE_DRIVE) == SELECT_SLAVE_DRIVE)
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
                if (self.driveId and not (<AtaDrive>self.drive[self.driveId]).isLoaded):
                    IF COMP_DEBUG:
                        if (self.ata.main.debugEnabled):
                            self.ata.main.notice("AtaController::outPort: selected slave, but it's not present; return")
                    return
                if (self.irq):
                    (<Pic>self.ata.main.platform.pic).lowerIrq(self.irq)
                with gil:
                    self.result = self.data = b''
                #self.driveReady = self.seekComplete = False # TODO: HACK
                if (not self.useLBA):
                    self.sectorCount = self.sectorCountByte
                    self.lba = (<AtaDrive>self.drive[self.driveId]).ChsToSector(self.cylinder, self.head, self.sector)
                    IF COMP_DEBUG:
                        if (self.ata.main.debugEnabled):
                            self.ata.main.notice("AtaController::outPort: test3: lba==%u, cylinder==%u, head==%u, sector==%u, sectorCount==%u", self.lba, self.cylinder, self.head, self.sector, self.sectorCount)
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
                        with gil:
                            self.result = b'\x00\x01\x01'
                            self.result += ((<AtaDrive>self.drive[self.driveId]).driveCode).to_bytes(length=OP_SIZE_WORD, byteorder="big", signed=False)
                            self.result += b'\x00'
                    else:
                        self.abortCommand()
                        return
                elif (data == COMMAND_RECALIBRATE):
                    if (not (<AtaDrive>self.drive[self.driveId]).isLoaded):
                        self.errorCommand(0x02)
                        return
                    self.cylinder = 0
                elif (data in (COMMAND_IDENTIFY_DEVICE, COMMAND_IDENTIFY_DEVICE_PACKET)):
                    if (not (<AtaDrive>self.drive[self.driveId]).isLoaded):
                        self.abortCommand()
                        return
                    if ((self.controllerId == 0 and data == COMMAND_IDENTIFY_DEVICE_PACKET) or (self.controllerId == 1 and data == COMMAND_IDENTIFY_DEVICE)):
                        if (self.controllerId == 1 and data == COMMAND_IDENTIFY_DEVICE):
                            self.setSignature(self.driveId)
                        self.abortCommand()
                        return
                    self.driveReady = self.seekComplete = True
                    with gil:
                        self.result = (<AtaDrive>self.drive[self.driveId]).configSpace.csRead(0, 512)
                elif (data in (COMMAND_READ_LBA28, COMMAND_READ_LBA28_WITHOUT_RETRIES, COMMAND_READ_LBA48, COMMAND_READ_MULTIPLE_LBA28, COMMAND_READ_MULTIPLE_LBA48, COMMAND_READ_DMA, COMMAND_READ_DMA_EXT)):
                    if (data in (COMMAND_READ_LBA28, COMMAND_READ_LBA28_WITHOUT_RETRIES, COMMAND_READ_MULTIPLE_LBA28, COMMAND_READ_DMA)):
                        self.convertToLBA28()
                    if (data in (COMMAND_READ_MULTIPLE_LBA28, COMMAND_READ_MULTIPLE_LBA48)):
                        if (not self.multipleSectors):
                            self.abortCommand()
                            return
                    with gil:
                        self.result = (<AtaDrive>self.drive[self.driveId]).readSectors(self.lba, self.sectorCount)
                elif (data in (COMMAND_VERIFY_SECTORS_LBA28, COMMAND_VERIFY_SECTORS_LBA28_NO_RETRY, COMMAND_VERIFY_SECTORS_LBA48)):
                    if (data in (COMMAND_VERIFY_SECTORS_LBA28, COMMAND_VERIFY_SECTORS_LBA28_NO_RETRY)):
                        self.convertToLBA28()
                    if (not (<AtaDrive>self.drive[self.driveId]).isLoaded or (<AtaDrive>self.drive[self.driveId]).driveType != ATA_DRIVE_TYPE_HD):
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
                    if (not (<AtaDrive>self.drive[self.driveId]).isLoaded or (<AtaDrive>self.drive[self.driveId]).driveType != ATA_DRIVE_TYPE_HD):
                        self.abortCommand()
                        return
                    if ((self.sectorCount != SPT) or (self.head and self.head != HEADS-1)):
                        self.abortCommand()
                        return
                    self.driveReady = True
                elif (data == COMMAND_SET_FEATURES):
                    if (self.features == 3):
                        if ((self.sectorCount >> 3) in (0, 1)):
                            self.mdmaMode = 0
                            self.udmaMode = 0
                        elif ((self.sectorCount >> 3) == 4):
                            self.mdmaMode = 1<<(self.sectorCount&0x7)
                            self.udmaMode = 0
                        elif ((self.sectorCount >> 3) == 8):
                            self.mdmaMode = 0
                            self.udmaMode = 1<<(self.sectorCount&0x7)
                        else:
                            self.abortCommand()
                            return
                        with gil:
                            (<AtaDrive>self.drive[self.driveId]).writeValue(63, 0x7 | (self.mdmaMode << 8))
                            (<AtaDrive>self.drive[self.driveId]).writeValue(88, 0x3f | (self.udmaMode << 8))
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
                    if (not (<AtaDrive>self.drive[self.driveId]).isLoaded or (<AtaDrive>self.drive[self.driveId]).driveType != ATA_DRIVE_TYPE_HD):
                        self.abortCommand()
                        return
                    if (not (<AtaDrive>self.drive[self.driveId]).isLocked):
                        (<AtaDrive>self.drive[self.driveId]).isLocked = True
                        self.err = False
                    else:
                        with gil:
                            if (not (<AtaDrive>self.drive[self.driveId]).filename or not access((<AtaDrive>self.drive[self.driveId]).filename, F_OK | R_OK) or not samefile((<AtaDrive>self.drive[self.driveId]).fp.fileno(), (<AtaDrive>self.drive[self.driveId]).filename)):
                                self.errorRegister |= (ATA_ERROR_REG_MC | ATA_ERROR_REG_MCR)
                                self.err = True
                elif (data == COMMAND_MEDIA_UNLOCK):
                    if (not (<AtaDrive>self.drive[self.driveId]).isLoaded or (<AtaDrive>self.drive[self.driveId]).driveType != ATA_DRIVE_TYPE_HD):
                        self.abortCommand()
                        return
                    with gil:
                        if (not (<AtaDrive>self.drive[self.driveId]).filename or not access((<AtaDrive>self.drive[self.driveId]).filename, F_OK | R_OK) or not samefile((<AtaDrive>self.drive[self.driveId]).fp.fileno(), (<AtaDrive>self.drive[self.driveId]).filename)):
                            (<AtaDrive>self.drive[self.driveId]).loadDrive((<AtaDrive>self.drive[self.driveId]).filename)
                            self.errorRegister |= (ATA_ERROR_REG_MC | ATA_ERROR_REG_MCR)
                            self.err = True
                        elif ((<AtaDrive>self.drive[self.driveId]).isLocked):
                            (<AtaDrive>self.drive[self.driveId]).isLocked = False
                            self.err = False
                elif (data == COMMAND_READ_NATIVE_MAX_ADDRESS):
                    if (not (<AtaDrive>self.drive[self.driveId]).isLoaded or (<AtaDrive>self.drive[self.driveId]).driveType != ATA_DRIVE_TYPE_HD or not self.useLBA):
                        self.abortCommand()
                        return
                    self.lba = (<AtaDrive>self.drive[self.driveId]).sectors
                    self.sector = self.lba & BITMASK_BYTE
                    self.cylinder = (self.lba >> 8) & BITMASK_WORD
                    self.head = (self.lba >> 24) & 0xf
                    self.driveReady = self.seekComplete = True
                elif (data == COMMAND_READ_NATIVE_MAX_ADDRESS_EXT):
                    if (not (<AtaDrive>self.drive[self.driveId]).isLoaded or (<AtaDrive>self.drive[self.driveId]).driveType != ATA_DRIVE_TYPE_HD or not self.useLBA):
                        self.abortCommand()
                        return
                    self.lba = (<AtaDrive>self.drive[self.driveId]).sectors
                    if (self.useLBA48):
                        self.sector = self.lba & BITMASK_BYTE
                        self.cylinder = (self.lba >> 8) & BITMASK_WORD
                    else:
                        self.sector = self.lba & BITMASK_BYTE
                        self.cylinder = (self.lba >> 8) & BITMASK_WORD
                        self.head = (self.lba >> 24) & 0xf
                    self.driveReady = self.seekComplete = True
                elif (data == COMMAND_SET_MAX_ADDRESS):
                    #if (not (<AtaDrive>self.drive[self.driveId]).isLoaded or (<AtaDrive>self.drive[self.driveId]).driveType != ATA_DRIVE_TYPE_HD or not self.useLBA):
                    IF 1:
                        self.abortCommand()
                        return
                elif (data == COMMAND_CHECK_POWER_MODE): # TODO?
                    #self.sectorCount = self.sectorCountByte = 0xff
                    #self.driveReady = True
                    IF 1:
                        self.abortCommand()
                        return
                elif (data == COMMAND_IDLE_IMMEDIATE): # TODO?
                    IF 1:
                        self.abortCommand()
                        return
                elif (data == COMMAND_FLUSH_CACHE):
                    self.driveReady = True
                elif (data == COMMAND_SECURITY_FREEZE_LOCK):
                    self.abortCommand()
                    return
                else:
                    self.ata.main.exitError("AtaController::outPort: unknown command 2: controllerId: %u; driveId: %u; ioPortAddr: 0x%04x; data: 0x%02x; dataSize: %u", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
                    return
                self.raiseAtaIrq(data not in (COMMAND_RECALIBRATE, COMMAND_EXECUTE_DRIVE_DIAGNOSTIC, COMMAND_INITIALIZE_DRIVE_PARAMETERS, COMMAND_RESET, COMMAND_SET_FEATURES, COMMAND_SET_MULTIPLE_MODE, COMMAND_VERIFY_SECTORS_LBA28, COMMAND_VERIFY_SECTORS_LBA28_NO_RETRY, COMMAND_VERIFY_SECTORS_LBA48, COMMAND_MEDIA_LOCK, COMMAND_MEDIA_UNLOCK, COMMAND_READ_DMA, COMMAND_READ_DMA_EXT, COMMAND_WRITE_DMA, COMMAND_WRITE_DMA_EXT, COMMAND_WRITE_DMA_FUA_EXT, COMMAND_READ_NATIVE_MAX_ADDRESS, COMMAND_READ_NATIVE_MAX_ADDRESS_EXT, COMMAND_CHECK_POWER_MODE), data not in (COMMAND_RESET, COMMAND_PACKET, COMMAND_READ_DMA, COMMAND_READ_DMA_EXT, COMMAND_WRITE_DMA, COMMAND_WRITE_DMA_EXT, COMMAND_WRITE_DMA_FUA_EXT))
            elif (ioPortAddr == 0x1fe or ioPortAddr == 0x206):
                prevReset = self.doReset
                self.irqEnabled = ((data & CONTROL_REG_NIEN) != CONTROL_REG_NIEN)
                self.doReset = ((data & CONTROL_REG_SRST) == CONTROL_REG_SRST)
                self.HOB = ((data & CONTROL_REG_HOB) == CONTROL_REG_HOB)
                IF COMP_DEBUG:
                    if (self.ata.main.debugEnabled):
                        self.ata.main.notice("AtaController::outPort: test2: prevReset==%u; doReset==%u; resetInProgress==%u; irqEnabled==%u; HOB==%u", prevReset, self.doReset, self.resetInProgress, self.irqEnabled, self.HOB)
                if (not prevReset and self.doReset):
                    self.reset(True)
                elif (self.resetInProgress and not self.doReset):
                    self.driveBusy = self.resetInProgress = False
                    self.driveReady = True
                    self.setSignature(self.driveId)
            else:
                self.ata.main.exitError("AtaController::outPort: TODO: controllerId: %u; driveId: %u; ioPortAddr: 0x%04x; data: 0x%02x; dataSize: %u", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
        else:
            self.ata.main.exitError("AtaController::outPort: dataSize %u not supported.", dataSize)
    cdef void run(self):
        if (self.controllerId == 0):
            self.ata.pciDevice.configSpace.csWriteValueWord(0x40, 0x8000)
            if (self.ata.main.hdaFilename): (<AtaDrive>self.drive[0]).loadDrive(self.ata.main.hdaFilename)
            if (self.ata.main.hdbFilename): (<AtaDrive>self.drive[1]).loadDrive(self.ata.main.hdbFilename)
        elif (self.controllerId == 1):
            self.ata.pciDevice.configSpace.csWriteValueWord(0x42, 0x8000)
            if (self.ata.main.cdrom1Filename): (<AtaDrive>self.drive[0]).loadDrive(self.ata.main.cdrom1Filename)
            if (self.ata.main.cdrom2Filename): (<AtaDrive>self.drive[1]).loadDrive(self.ata.main.cdrom2Filename)


cdef class Ata:
    def __init__(self, Hirnwichse main):
        cdef AtaController controller0, controller1
        self.main = main
        controller0 = AtaController(self, 0)
        self.controller[0] = <PyObject*>controller0
        controller1 = AtaController(self, 1)
        self.controller[1] = <PyObject*>controller1
        #self.controller[2] = NULL
        #self.controller[3] = NULL
        self.pciDevice = (<Pci>self.main.platform.pci).addDevice()
        self.pciDevice.setVendorDeviceId(PCI_VENDOR_ID_INTEL, 0x7010)
        self.pciDevice.setDeviceClass(PCI_CLASS_PATA)
        #self.pciDevice.setBarSize(0, 4) # TODO?
        #self.pciDevice.setBarSize(1, 4) # TODO?
        #self.pciDevice.setBarSize(2, 4) # TODO?
        #self.pciDevice.setBarSize(3, 4) # TODO?
        #self.pciDevice.setBarSize(4, 4) # TODO?
        self.pciDevice.setBarSize(4, 4) # TODO?
        #self.pciDevice.configSpace.csWriteValueByte(PCI_COMMAND, 0x5)
        self.pciDevice.configSpace.csWriteValueByte(PCI_COMMAND, 0x1)
        self.pciDevice.configSpace.csWriteValueWord(PCI_STATUS, 0x280)
        self.pciDevice.configSpace.csWriteValueByte(PCI_PROG_IF, 0x80)
        #self.pciDevice.configSpace.csWriteValueByte(PCI_PROG_IF, 0x8a)
        #self.pciDevice.configSpace.csWriteValueByte(PCI_INTERRUPT_LINE, 14)
        #self.pciDevice.configSpace.csWriteValueByte(PCI_INTERRUPT_PIN, 1)
        #self.pciDevice.configSpace.csWriteValueDword(PCI_BASE_ADDRESS_0, 0x1f1)
        #self.pciDevice.configSpace.csWriteValueDword(PCI_BASE_ADDRESS_1, 0x3f5)
        #self.pciDevice.configSpace.csWriteValueDword(PCI_BASE_ADDRESS_2, 0x171)
        #self.pciDevice.configSpace.csWriteValueDword(PCI_BASE_ADDRESS_3, 0x375)
        #self.pciDevice.configSpace.csWriteValueDword(PCI_BASE_ADDRESS_4, 0xc001)
        self.pciDevice.configSpace.csWriteValueDword(PCI_BASE_ADDRESS_4, 0x1)
        self.base4Addr = 0x0
        Py_INCREF(controller0)
        Py_INCREF(controller1)
        #Py_INCREF(controller2)
        #Py_INCREF(controller3)
    cdef void reset(self) nogil:
        if (self.controller[0]):
            (<AtaController>self.controller[0]).reset(False)
        if (self.controller[1]):
            (<AtaController>self.controller[1]).reset(False)
        #if (self.controller[2]):
        #    (<AtaController>self.controller[2]).reset(False)
        #if (self.controller[3]):
        #    (<AtaController>self.controller[3]).reset(False)
    cdef uint8_t isBusmaster(self, uint16_t ioPortAddr) nogil:
        cdef uint32_t temp
        #temp = self.pciDevice.getData(PCI_BASE_ADDRESS_4, OP_SIZE_DWORD)
        temp = self.base4Addr
        if (temp == BITMASK_DWORD or not (temp&1)):
            return False
        temp = temp&0xfffc
        if (not temp):
            return False
        if (ioPortAddr >= temp and ioPortAddr < temp+16):
            return True
        return False
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil:
        cdef uint8_t isBusmaster = 0
        cdef uint32_t ret = BITMASKS_FF[dataSize]
        isBusmaster = self.isBusmaster(ioPortAddr)
        #if (self.main.debugEnabled):
        #IF 1:
        IF COMP_DEBUG:
            if (ioPortAddr&0xf or isBusmaster or self.main.debugEnabled):
                #self.main.debug("Ata::inPort1: ioPortAddr: 0x%04x; dataSize: %u", ioPortAddr, dataSize)
                self.main.notice("Ata::inPort1: ioPortAddr: 0x%04x; dataSize: %u", ioPortAddr, dataSize)
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
                #self.main.debug("Ata::inPort2: ioPortAddr: 0x%04x; dataSize: %u; ret: 0x%04x", ioPortAddr, dataSize, ret)
                self.main.notice("Ata::inPort2: ioPortAddr: 0x%04x; dataSize: %u; ret: 0x%04x", ioPortAddr, dataSize, ret)
            return ret
        elif (dataSize == OP_SIZE_DWORD and (ioPortAddr&0xf)):
            ret = self.inPort(ioPortAddr, OP_SIZE_WORD)
            ret |= self.inPort(ioPortAddr, OP_SIZE_WORD) << 16
            #if (self.main.debugEnabled):
            #IF 1:
            IF COMP_DEBUG:
                #self.main.debug("Ata::inPort3: ioPortAddr: 0x%04x; dataSize: %u; ret: 0x%08x", ioPortAddr, dataSize, ret)
                self.main.notice("Ata::inPort3: ioPortAddr: 0x%04x; dataSize: %u; ret: 0x%08x", ioPortAddr, dataSize, ret)
            return ret
        if (isBusmaster):
            if (not ((ioPortAddr-(self.pciDevice.getData(PCI_BASE_ADDRESS_4, OP_SIZE_DWORD) & 0xfffc)) & 0x8)):
                ret = (<AtaController>self.controller[0]).inPort(ioPortAddr, dataSize)
            else:
                ret = (<AtaController>self.controller[1]).inPort(ioPortAddr, dataSize)
        elif (ioPortAddr in ATA1_PORTS_TUPLE and self.controller[0]):
            ret = (<AtaController>self.controller[0]).inPort(ioPortAddr-ATA1_BASE, dataSize)
        elif (ioPortAddr in ATA2_PORTS_TUPLE and self.controller[1]):
            ret = (<AtaController>self.controller[1]).inPort(ioPortAddr-ATA2_BASE, dataSize)
        #elif (ioPortAddr in ATA3_PORTS_TUPLE and self.controller[2]):
        #    ret = (<AtaController>self.controller[2]).inPort(ioPortAddr-ATA3_BASE, dataSize)
        #elif (ioPortAddr in ATA4_PORTS_TUPLE and self.controller[3]):
        #    ret = (<AtaController>self.controller[3]).inPort(ioPortAddr-ATA4_BASE, dataSize)
        #if (self.main.debugEnabled):
        #IF 1:
        IF COMP_DEBUG:
            if (ioPortAddr&0xf or isBusmaster or self.main.debugEnabled):
                #self.main.debug("Ata::inPort4: ioPortAddr: 0x%04x; dataSize: %u; ret: 0x%02x", ioPortAddr, dataSize, ret)
                self.main.notice("Ata::inPort4: ioPortAddr: 0x%04x; dataSize: %u; ret: 0x%02x", ioPortAddr, dataSize, ret)
        return ret
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil:
        cdef uint8_t isBusmaster = 0
        isBusmaster = self.isBusmaster(ioPortAddr)
        #if (self.main.debugEnabled):
        #IF 1:
        IF COMP_DEBUG:
            if (ioPortAddr&0xf or isBusmaster or self.main.debugEnabled):
                #self.main.debug("Ata::outPort: ioPortAddr: 0x%04x; data: 0x%02x; dataSize: %u", ioPortAddr, data, dataSize)
                self.main.notice("Ata::outPort: ioPortAddr: 0x%04x; data: 0x%02x; dataSize: %u", ioPortAddr, data, dataSize)
                #if (ioPortAddr == 0x1f3 and data == 0xfc):
                #    self.main.debugEnabledTest = self.main.debugEnabled = True
        if (isBusmaster and dataSize != OP_SIZE_BYTE):
            if (dataSize == OP_SIZE_WORD):
                self.outPort(ioPortAddr, <uint8_t>data, OP_SIZE_BYTE)
                self.outPort(ioPortAddr+1, <uint8_t>(data >> 8), OP_SIZE_BYTE)
                return
            elif (dataSize == OP_SIZE_DWORD):
                self.outPort(ioPortAddr, <uint16_t>data, OP_SIZE_WORD)
                self.outPort(ioPortAddr+2, <uint16_t>(data >> 16), OP_SIZE_WORD)
                return
        elif (dataSize == OP_SIZE_WORD and (ioPortAddr&0xf)):
            self.outPort(ioPortAddr, <uint8_t>data, OP_SIZE_BYTE)
            self.outPort(ioPortAddr, <uint8_t>(data >> 8), OP_SIZE_BYTE)
            return
        elif (dataSize == OP_SIZE_DWORD and (ioPortAddr&0xf)):
            self.outPort(ioPortAddr, <uint16_t>data, OP_SIZE_WORD)
            self.outPort(ioPortAddr, <uint16_t>(data >> 16), OP_SIZE_WORD)
            return
        if (isBusmaster):
            if (not ((ioPortAddr-(self.pciDevice.getData(PCI_BASE_ADDRESS_4, OP_SIZE_DWORD) & 0xfffc)) & 0x8)):
                (<AtaController>self.controller[0]).outPort(ioPortAddr, data, dataSize)
            else:
                (<AtaController>self.controller[1]).outPort(ioPortAddr, data, dataSize)
        elif (ioPortAddr in ATA1_PORTS_TUPLE and self.controller[0]):
            (<AtaController>self.controller[0]).outPort(ioPortAddr-ATA1_BASE, data, dataSize)
        elif (ioPortAddr in ATA2_PORTS_TUPLE and self.controller[1]):
            (<AtaController>self.controller[1]).outPort(ioPortAddr-ATA2_BASE, data, dataSize)
        #elif (ioPortAddr in ATA3_PORTS_TUPLE and self.controller[2]):
        #    (<AtaController>self.controller[2]).outPort(ioPortAddr-ATA3_BASE, data, dataSize)
        #elif (ioPortAddr in ATA4_PORTS_TUPLE and self.controller[3]):
        #    (<AtaController>self.controller[3]).outPort(ioPortAddr-ATA4_BASE, data, dataSize)
    cdef void run(self):
        self.reset()
        if (self.controller[0]):
            (<AtaController>self.controller[0]).run()
        if (self.controller[1]):
            (<AtaController>self.controller[1]).run()
        #if (self.controller[2]):
        #    (<AtaController>self.controller[2]).run()
        #if (self.controller[3]):
        #    (<AtaController>self.controller[3]).run()


