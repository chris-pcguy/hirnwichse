
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
DEF CONTROL_REG_SKC = 0x10
DEF CONTROL_REG_SHOULD_BE_SET = 0x8 # according to bochs' rombios, this should ALWAYS be set. (should != is)
DEF CONTROL_REG_SRST = 0x4
DEF CONTROL_REG_NIEN = 0x2

DEF COMMAND_RESET = 0x08
DEF COMMAND_READ_LBA28 = 0x20
DEF COMMAND_WRITE_LBA28 = 0x30
DEF COMMAND_PACKET = 0xa0
DEF COMMAND_IDENTIFY_DEVICE_PACKET = 0xa1
DEF COMMAND_IDENTIFY_DEVICE = 0xec

DEF PACKET_COMMAND_TEST_UNIT_READY = 0x00
DEF PACKET_COMMAND_REQUEST_SENSE = 0x03
DEF PACKET_COMMAND_READ_CAPACITY = 0x25
DEF PACKET_COMMAND_READ_10 = 0x28

DEF FD_HD_SECTOR_SIZE = 512
DEF FD_HD_SECTOR_SHIFT = 9

DEF CD_SECTOR_SIZE = 2048
DEF CD_SECTOR_SHIFT = 11

cdef class AtaDrive:
    def __init__(self, AtaController ataController, object main, unsigned char driveId, unsigned char driveType):
        self.ataController = ataController
        self.main = main
        self.driveId = driveId
        self.driveType = driveType
        self.isLoaded = False
        self.isWriteProtected = True
        self.diskSize = 0
        if (self.driveType == ATA_DRIVE_TYPE_CDROM):
            self.sectorShift = CD_SECTOR_SHIFT
            self.sectorSize = CD_SECTOR_SIZE
        else:
            self.sectorShift = FD_HD_SECTOR_SHIFT
            self.sectorSize = FD_HD_SECTOR_SIZE
        self.configSpace = ConfigSpace(512, self.main)
    cdef unsigned int ChsToSector(self, unsigned char cylinder, unsigned char head, unsigned char sector):
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
            self.main.notice("HD{0:d}: loadDrive: file isn't found/accessable.", (self.ataController.controllerId << 1)+self.driveId)
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
            self.main.notice("HD{0:d}: loadDrive: file isn't found/accessable. (filename: {1:s}, access-cmd)", (self.ataController.controllerId << 1)+self.driveId, filename.decode())
            return
        self.fp.seek(0, SEEK_END)
        self.diskSize = self.fp.tell()
        self.fp.seek(0)
        #self.writeValue(0, 0x80) # word 0 ; fixed drive
        cylinders = self.diskSize / (HEADS * (SPT << self.sectorShift))
        if (cylinders > 16383):
            cylinders = 16383
        self.writeValue(1, cylinders) # word 1 ; cylinders
        self.writeValue(3, HEADS) # word 3 ; heads
        self.writeValue(4, SPT << self.sectorShift) # word 4 ; spt * self.sectorSize
        self.writeValue(5, self.sectorSize) # hdd block size
        self.writeValue(6, SPT) # word 6 ; spt
        self.writeValue(20, 2) # type
        self.writeValue(21, self.sectorSize) # increment in hdd block size
        self.writeValue(49, (1 << 9)) # supports lba
        self.writeValue(83, (1 << 10)) # supports lba48
        self.writeValue(86, (1 << 10)) # supports lba48
        self.configSpace.csWriteValue(60 << 1, self.diskSize >> self.sectorShift, OP_SIZE_DWORD) # total number of addressable blocks. (diskSize >> self.sectorShift == diskSize/self.sectorSize)
        self.configSpace.csWriteValue(100 << 1, self.diskSize >> self.sectorShift, OP_SIZE_QWORD) # total number of addressable blocks. (diskSize >> self.sectorShift == diskSize/self.sectorSize)
        #if (cylinders <= 1024): # hardcoded
        if (cylinders <= 2048): # hardcoded
            translateValueTemp = ATA_TRANSLATE_NONE
        elif ((cylinders * HEADS) <= 131072):
            translateValueTemp = ATA_TRANSLATE_LARGE
        else:
            translateValueTemp = ATA_TRANSLATE_LBA
        translateReg = CMOS_ATA_0_1_TRANSLATION if (self.ataController.controllerId in (0, 1)) else CMOS_ATA_2_3_TRANSLATION
        translateValue = (<Cmos>self.main.platform.cmos).readValue(translateReg, OP_SIZE_BYTE)
        translateValue |= (translateValueTemp << (((self.ataController.controllerId&1)<<2)+(self.driveId<<1)))
        (<Cmos>self.main.platform.cmos).writeValue(translateReg, translateValue, OP_SIZE_BYTE)
        if (self.ataController.controllerId == 0 and self.driveId in (0, 1)):
            self.writeValue(0, 0xff80) # word 0 ; ata; fixed drive
            cmosDiskType = (<Cmos>self.main.platform.cmos).readValue(CMOS_HDD_DRIVE_TYPE, OP_SIZE_BYTE)
            cmosDiskType |= (0xf0 if (self.driveId == 0) else 0x0f)
            (<Cmos>self.main.platform.cmos).writeValue(CMOS_HDD_DRIVE_TYPE, cmosDiskType, OP_SIZE_BYTE)
            (<Cmos>self.main.platform.cmos).writeValue((CMOS_HD0_EXTENDED_DRIVE_TYPE if (self.driveId == 0) else CMOS_HD1_EXTENDED_DRIVE_TYPE), 0x2f, OP_SIZE_BYTE)
            (<Cmos>self.main.platform.cmos).writeValue((CMOS_HD0_CYLINDERS if (self.driveId == 0) else CMOS_HD1_CYLINDERS), cylinders, OP_SIZE_WORD)
            (<Cmos>self.main.platform.cmos).writeValue((CMOS_HD0_LANDING_ZONE if (self.driveId == 0) else CMOS_HD1_LANDING_ZONE), cylinders, OP_SIZE_WORD)
            (<Cmos>self.main.platform.cmos).writeValue((CMOS_HD0_WRITE_PRECOMP if (self.driveId == 0) else CMOS_HD1_WRITE_PRECOMP), 0xffff, OP_SIZE_WORD)
            (<Cmos>self.main.platform.cmos).writeValue((CMOS_HD0_HEADS if (self.driveId == 0) else CMOS_HD1_HEADS), HEADS, OP_SIZE_BYTE)
            (<Cmos>self.main.platform.cmos).writeValue((CMOS_HD0_SPT if (self.driveId == 0) else CMOS_HD1_SPT), SPT, OP_SIZE_BYTE)
            if (self.driveId == 0):
                (<Cmos>self.main.platform.cmos).writeValue(CMOS_HD0_CONTROL_BYTE, 0xc8, OP_SIZE_BYTE) # hardcoded
            else:
                (<Cmos>self.main.platform.cmos).writeValue(CMOS_HD1_CONTROL_BYTE, 0x80, OP_SIZE_BYTE) # hardcoded
        else:
            self.writeValue(0, 0x0580) # word 0 ; atapi; removable drive
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
            self.main.exitError("AtaDrive::writeBytes: tried to write to optical drive!")
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
    def __init__(self, Ata ata, object main, unsigned char controllerId):
        cdef unsigned char driveType # HACK
        self.ata = ata
        self.main = main
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
        self.drive = (AtaDrive(self, self.main, 0, driveType), AtaDrive(self, self.main, 1, driveType))
        self.result = self.data = b''
    cdef void reset(self, unsigned char swReset):
        cdef AtaDrive drive
        self.drq = self.err = self.useLBA = self.useLBA48 = False
        self.seekComplete = self.irqEnabled = True
        self.cmd = 0
        self.errorRegister = 0
        self.lowerAtaIrq()
        if (not swReset):
            self.doReset = self.driveBusy = self.resetInProgress = False
            self.driveReady = True
        else:
            self.driveReady = False
            self.driveBusy = self.resetInProgress = True
        for drive in self.drive:
            drive.reset()
    cdef void raiseAtaIrq(self):
        if (self.irq and self.irqEnabled):
            (<Pic>self.main.platform.pic).raiseIrq(self.irq)
        self.drq = True
        self.driveBusy = self.err = False
        self.errorRegister = 0
    cdef void lowerAtaIrq(self):
        if (self.irq):
            (<Pic>self.main.platform.pic).lowerIrq(self.irq)
        self.driveReady = True
        self.drq = self.err = False
        self.errorRegister = 0
    cdef void abortCommand(self):
        self.errorCommand(0x04)
    cdef void errorCommand(self, unsigned char errorRegister):
        self.cmd = 0
        self.driveBusy = self.drq = False
        self.driveReady = self.err = True
        self.errorRegister = errorRegister
        self.result = self.data = b''
        if (self.irq and self.irqEnabled):
            (<Pic>self.main.platform.pic).raiseIrq(self.irq)
    cdef void handlePacket(self):
        cdef AtaDrive drive
        cdef unsigned char cmd
        cdef unsigned int sectorCount
        cdef unsigned long int lba
        drive = self.drive[self.driveId]
        cmd = self.data[0]
        if (not drive.isLoaded):
            self.errorCommand(0x2)
        if (cmd == PACKET_COMMAND_TEST_UNIT_READY):
            if (int.from_bytes(self.data[1:], byteorder="big", signed=False)):
                self.main.exitError("AtaController::handlePacket_1: rest of data packet is not zero! self.data == {0:s}", repr(self.data))
                return
            self.result = b'\x00'*8
        elif (cmd == PACKET_COMMAND_REQUEST_SENSE):
            self.result = b'\x00'*12
            if (not drive.isLoaded):
                self.result += b'\x3a'
            else:
                self.result += b'\x00'
            self.result += b'\x00'
            #self.result += b'\x04\x01'
            self.result += b'\x00'*4
        elif (cmd == PACKET_COMMAND_READ_CAPACITY):
            if (int.from_bytes(self.data[1:], byteorder="big", signed=False)):
                self.main.exitError("AtaController::handlePacket_2: rest of data packet is not zero! self.data == {0:s}", repr(self.data))
                return
            self.result = (drive.diskSize >> CD_SECTOR_SHIFT).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
            self.result += (CD_SECTOR_SIZE).to_bytes(length=OP_SIZE_DWORD, byteorder="big", signed=False)
        elif (cmd == PACKET_COMMAND_READ_10):
            if (0 not in (self.data[1], self.data[6], self.data[9], self.data[10], self.data[11])):
                self.main.exitError("AtaController::handlePacket: self.data[1,6,9,10 or 11] are not zero! self.data == {0:s}", repr(self.data))
                return
            lba = int.from_bytes(self.data[2:2+OP_SIZE_DWORD], byteorder="big", signed=False)
            sectorCount = int.from_bytes(self.data[7:7+OP_SIZE_WORD], byteorder="big", signed=False)
            self.result = drive.readSectors(lba, sectorCount)
        else:
            self.main.exitError("AtaController::handlePacket: cmd is unknown! cmd == {0:#04x}", cmd)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef AtaDrive drive
        cdef unsigned char ret = BITMASK_BYTE
        drive = self.drive[self.driveId]
        if (dataSize == OP_SIZE_BYTE):
            #if (ioPortAddr >= 0x1 and ioPortAddr <= 0x5 and not drive.isLoaded):
            #    return 0
            if (not drive.isLoaded):
                return BITMASK_BYTE
            if (ioPortAddr == 0x0): # data port
                if (not len(self.result)):
                    self.lowerAtaIrq()
                    self.main.notice("AtaController::inPort: data port is empty, returning BITMASK_BYTE; controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
                    return ret
                ret = self.result[0]
                self.result = self.result[1:]
                if (not len(self.result)):
                    self.lowerAtaIrq()
                else:
                    self.raiseAtaIrq()
            elif (ioPortAddr == 0x1):
                return self.errorRegister
            elif (ioPortAddr == 0x2):
                if (self.cmd == COMMAND_PACKET and not len(self.result)):
                    self.sectorCountByte = 3
                ret = self.sectorCountByte & BITMASK_BYTE
            elif (ioPortAddr == 0x3):
                ret = self.sector & BITMASK_BYTE
            elif (ioPortAddr == 0x4):
                if (self.cmd == COMMAND_PACKET and len(self.result) <= BITMASK_WORD):
                    self.cylinder = len(self.result) # return length
                ret = self.cylinder & BITMASK_BYTE
            elif (ioPortAddr == 0x5):
                if (self.cmd == COMMAND_PACKET and len(self.result) <= BITMASK_WORD):
                    self.cylinder = len(self.result) # return length
                ret = (self.cylinder >> 8) & BITMASK_BYTE
            elif (ioPortAddr == 0x6):
                ret = (0xa0) | (self.useLBA << 6) | (self.driveId << 4) | (((self.lba >> 24) if (self.useLBA) else self.head) & 0xf)
            elif (ioPortAddr == 0x7 or ioPortAddr == 0x1fe or ioPortAddr == 0x206):
                if (ioPortAddr == 0x7 and self.irq):
                    (<Pic>self.main.platform.pic).lowerIrq(self.irq)
                if (not drive.isLoaded):
                    #self.main.notice("AtaController::inPort: drive isn't loaded: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
                    return 0x00
                ret = (self.driveBusy << 7) | (self.driveReady << 6) | (self.seekComplete << 4) | (self.drq << 3) | (self.err)
            elif (ioPortAddr == 0x1ff or ioPortAddr == 0x207):
                self.main.exitError("AtaController::inPort: what??? ;controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
                return BITMASK_BYTE
            else:
                self.main.notice("AtaController::inPort: TODO: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; dataSize: {3:d}", self.controllerId, self.driveId, ioPortAddr, dataSize)
        else:
            self.main.exitError("AtaController::inPort: dataSize {0:d} not supported.", dataSize)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef AtaDrive drive
        cdef unsigned char prevReset
        drive = self.drive[self.driveId]
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x0): # data port
                self.data += bytes([data])
                if (self.cmd == COMMAND_WRITE_LBA28):
                    if (len(self.data) >> drive.sectorShift >= self.sectorCount):
                        drive.writeSectors(self.lba, self.sectorCount, self.data)
                        self.data = self.data[self.sectorCount << drive.sectorShift:]
                        self.lowerAtaIrq()
                    else:
                        self.raiseAtaIrq()
                elif (self.cmd == COMMAND_PACKET):
                    if (len(self.data) >= 12):
                        self.handlePacket()
                        self.raiseAtaIrq()
                    else:
                        self.lowerAtaIrq()
                else:
                    self.main.exitError("AtaController::outPort: unknown command 1: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}; cmd: {5:#04x}", self.controllerId, self.driveId, ioPortAddr, data, dataSize, self.cmd)
                    return
            elif (ioPortAddr == 0x1):
                pass
            elif (ioPortAddr == 0x2):
                if (not self.sectorCountFlipFlop):
                    self.sectorCount = (self.sectorCount & 0x00ff) | ((data & BITMASK_BYTE) << 8)
                else:
                    self.sectorCount = (self.sectorCount & 0xff00) | (data & BITMASK_BYTE)
                self.sectorCountByte = (data & BITMASK_BYTE)
                self.sectorCountFlipFlop = not self.sectorCountFlipFlop
            elif (ioPortAddr == 0x3):
                if (not self.sectorLowFlipFlop):
                    self.lba = (self.lba & 0xffff00ffffff) | ((data & BITMASK_BYTE) << 24)
                else:
                    self.lba = (self.lba & 0xffffffffff00) | (data & BITMASK_BYTE)
                self.sectorLowFlipFlop = not self.sectorLowFlipFlop
                self.sector = data & BITMASK_BYTE
            elif (ioPortAddr == 0x4):
                if (not self.sectorMiddleFlipFlop):
                    self.lba = (self.lba & 0xff00ffffffff) | (<unsigned long int>(data & BITMASK_BYTE) << 32)
                else:
                    self.lba = (self.lba & 0xffffffff00ff) | ((data & BITMASK_BYTE) << 8)
                self.sectorMiddleFlipFlop = not self.sectorMiddleFlipFlop
                self.cylinder = (self.cylinder & 0xff00) | (data & BITMASK_BYTE)
            elif (ioPortAddr == 0x5):
                if (not self.sectorHighFlipFlop):
                    self.lba = (self.lba & 0x00ffffffffff) | (<unsigned long int>(data & BITMASK_BYTE) << 40)
                else:
                    self.lba = (self.lba & 0xffffff00ffff) | ((data & BITMASK_BYTE) << 16)
                self.sectorHighFlipFlop = not self.sectorHighFlipFlop
                self.cylinder = (self.cylinder & 0x00ff) | ((data & BITMASK_BYTE) << 8)
            elif (ioPortAddr == 0x6):
                self.driveId = ((data & SELECT_SLAVE_DRIVE) == SELECT_SLAVE_DRIVE)
                drive = self.drive[self.driveId]
                self.useLBA = ((data & USE_LBA) == USE_LBA)
                self.useLBA48 = ((data & USE_LBA28) != USE_LBA28)
                self.head = data & 0xf
            elif (ioPortAddr == 0x7): # command port
                #if (self.driveId and not drive.isLoaded):
                #    self.main.notice("AtaController::outPort: selected slave, but it's not present; return")
                if (not drive.isLoaded):
                    self.main.notice("AtaController::outPort: it's not present; return")
                    self.errorCommand(0x2)
                    return
                self.cmd = data
                self.result = self.data = b''
                if (not self.useLBA):
                    self.sectorCount &= BITMASK_BYTE
                    self.lba = drive.ChsToSector(self.cylinder, self.head, self.sector)
                    self.sectorCount = self.sectorCountByte
                    self.main.debug("AtaController::outPort: test3: lba=={0:d}, cylinder=={1:d}, head=={2:d}, sector=={3:d}", self.lba, self.cylinder, self.head, self.sector)
                elif (not self.useLBA48):
                    self.lba = ((self.lba >> 24) & 0x0ffffff) | (self.head << 24)
                    self.sectorCount >>= 8
                if (data == COMMAND_RESET):
                    self.result = b'\x00\x01\x01\xeb\x14\x00'
                elif (data in (COMMAND_IDENTIFY_DEVICE, COMMAND_IDENTIFY_DEVICE_PACKET)):
                    if ((self.controllerId == 0 and data == COMMAND_IDENTIFY_DEVICE_PACKET) or (self.controllerId == 1 and data == COMMAND_IDENTIFY_DEVICE)):
                        self.abortCommand()
                        return
                    self.result = drive.configSpace.csRead(0, 512)
                elif (data == COMMAND_READ_LBA28):
                    self.result = drive.readSectors(self.lba, self.sectorCount)
                elif (data in (COMMAND_WRITE_LBA28, COMMAND_PACKET)):
                    pass # not handled here.
                else:
                    self.main.exitError("AtaController::outPort: unknown command 2: controllerId: {0:d}; driveId: {1:d}; ioPortAddr: {2:#06x}; data: {3:#04x}; dataSize: {4:d}", self.controllerId, self.driveId, ioPortAddr, data, dataSize)
                    return
                self.raiseAtaIrq()
            elif (ioPortAddr == 0x1fe or ioPortAddr == 0x206):
                if (not (data & CONTROL_REG_SHOULD_BE_SET)):
                    self.main.notice("AtaController::outPort: CONTROL_REG_SHOULD_BE_SET should be set! (obvious message is obvious.)")
                prevReset = self.doReset
                self.irqEnabled = ((data & CONTROL_REG_NIEN) != CONTROL_REG_NIEN)
                self.doReset = ((data & CONTROL_REG_SRST) == CONTROL_REG_SRST)
                self.main.debug("AtaController::outPort: test2: prevReset=={0:d}; doReset=={1:d}; resetInProgress=={2:d}", prevReset, self.doReset, self.resetInProgress)
                if (drive.isLoaded):
                    self.driveId = 0
                    if (self.controllerId == 0): # HACK: HD
                        self.cylinder = 0
                    elif (self.controllerId == 1): # HACK: CD
                        self.cylinder = 0xeb14
                    else:
                        self.main.exitError("AtaController::outPort: self.controllerId {0:d} is not in (0, 1).", self.controllerId)
                        return
                else:
                    self.cylinder = BITMASK_WORD
                self.lba = self.head = 0
                self.sectorCount = self.sectorCountByte = self.sector = 1
                self.sectorCountFlipFlop = self.sectorHighFlipFlop = self.sectorMiddleFlipFlop = self.sectorLowFlipFlop = False
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
        elif (self.controllerId == 1):
            if (self.main.cdromFilename): (<AtaDrive>self.drive[0]).loadDrive(self.main.cdromFilename)


cdef class Ata:
    def __init__(self, object main):
        self.main = main
        self.controller = (AtaController(self, self.main, 0), AtaController(self, self.main, 1))
        self.pciDevice = (<Pci>self.main.platform.pci).addDevice()
        self.pciDevice.setVendorDeviceId(0x8086, 0x7010)
        self.pciDevice.setDeviceClass(PCI_CLASS_PATA)
        self.pciDevice.setData(PCI_INTERRUPT_LINE, (14), OP_SIZE_BYTE)
        self.pciDevice.setData(PCI_PROG_IF, 0x80, OP_SIZE_BYTE)
    cdef void reset(self):
        cdef AtaController controller
        for controller in self.controller:
            controller.reset(False)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned int ret = BITMASK_BYTE
        self.main.debug("Ata::inPort1: ioPortAddr: {0:#06x}; dataSize: {1:d}", ioPortAddr, dataSize)
        if (dataSize == OP_SIZE_WORD):
            ret = self.inPort(ioPortAddr, OP_SIZE_BYTE)
            ret |= self.inPort(ioPortAddr, OP_SIZE_BYTE) << 8
            self.main.debug("Ata::inPort2: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#06x}", ioPortAddr, dataSize, ret)
            return ret
        elif (dataSize == OP_SIZE_DWORD):
            ret = self.inPort(ioPortAddr, OP_SIZE_WORD)
            ret |= self.inPort(ioPortAddr, OP_SIZE_WORD) << 16
            self.main.debug("Ata::inPort3: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#010x}", ioPortAddr, dataSize, ret)
            return ret
        if (ioPortAddr in ATA1_PORTS and len(self.controller) >= 1 and self.controller[0]):
            ret = (<AtaController>self.controller[0]).inPort(ioPortAddr-ATA1_BASE, dataSize)
        elif (ioPortAddr in ATA2_PORTS and len(self.controller) >= 2 and self.controller[1]):
            ret = (<AtaController>self.controller[1]).inPort(ioPortAddr-ATA2_BASE, dataSize)
        elif (ioPortAddr in ATA3_PORTS and len(self.controller) >= 3 and self.controller[2]):
            ret = (<AtaController>self.controller[2]).inPort(ioPortAddr-ATA3_BASE, dataSize)
        elif (ioPortAddr in ATA4_PORTS and len(self.controller) >= 4 and self.controller[3]):
            ret = (<AtaController>self.controller[3]).inPort(ioPortAddr-ATA4_BASE, dataSize)
        self.main.debug("Ata::inPort4: ioPortAddr: {0:#06x}; dataSize: {1:d}; ret: {2:#04x}", ioPortAddr, dataSize, ret)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        self.main.debug("Ata::outPort: ioPortAddr: {0:#06x}; data: {1:#04x}; dataSize: {2:d}", ioPortAddr, data, dataSize)
        if (dataSize == OP_SIZE_WORD):
            self.outPort(ioPortAddr, data & BITMASK_BYTE, OP_SIZE_BYTE)
            self.outPort(ioPortAddr, (data >> 8)&BITMASK_BYTE, OP_SIZE_BYTE)
            return
        elif (dataSize == OP_SIZE_DWORD):
            self.outPort(ioPortAddr, data & BITMASK_WORD, OP_SIZE_WORD)
            self.outPort(ioPortAddr, (data >> 16)&BITMASK_WORD, OP_SIZE_WORD)
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
        #self.reset()
        for controller in self.controller:
            controller.reset(False)
            controller.run()


