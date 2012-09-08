
from os import access, F_OK, R_OK, W_OK
from os.path import getsize


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
    def __init__(self, AtaController ataController, object main, unsigned char driveId):
        self.ataController = ataController
        self.main = main
        self.driveId = driveId
        self.isLoaded = False
        self.isWriteProtected = True
    cdef void reset(self):
        self.sector = self.sectorCount = 1
        self.sectorCountFlipFlop = self.sectorHighFlipFlop = self.sectorMiddleFlipFlop = self.sectorLowFlipFlop = False
    cdef void loadDrive(self, bytes filename):
        cdef unsigned char cmosDiskType
        if (not filename or not access(filename, F_OK | R_OK)):
            self.main.notice("HD{0:d}: loadDrive: file isn't found/accessable. (filename: {1:s})", (self.ataController.controllerId*2)+self.driveId, filename)
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
            self.main.notice("HD{0:d}: loadDrive: file isn't found/accessable. (filename: {1:s}, access-cmd)", (self.ataController.controllerId*2)+self.driveId, filename)
            return
        if (self.driveId in (0, 1)):
            cmosDiskType = (<Cmos>self.main.platform.cmos).readValue(CMOS_HDD_DRIVE_TYPE, OP_SIZE_BYTE)
            cmosDiskType |= (0xf0 if (self.driveId == 0) else 0x0f)
            (<Cmos>self.main.platform.cmos).writeValue(CMOS_HDD_DRIVE_TYPE, cmosDiskType, OP_SIZE_BYTE)
            (<Cmos>self.main.platform.cmos).writeValue((CMOS_HD0_EXTENDED_DRIVE_TYPE if (self.driveId == 0) else CMOS_HD1_EXTENDED_DRIVE_TYPE), 0x2f, OP_SIZE_BYTE)
    cdef void run(self):
        pass


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
        for drive in self.drive:
            drive.reset()
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef AtaDrive drive
        cdef unsigned char ret = BITMASK_BYTE
        drive = self.drive[self.driveId]
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
                if (not drive.isLoaded):
                    ret = 0x00
                else:
                    ret = (self.driveBusy << 7) | (self.driveReady << 6) | (self.seekComplete << 4) | (self.drq << 3) | \
                        (self.err)
                if (ioPortAddr == 0x7 and self.irq):
                    (<Pic>self.main.platform.pic).lowerIrq(self.irq)
            elif (ioPortAddr == 0x1ff or ioPortAddr == 0x207):
                return BITMASK_BYTE
            else:
                self.main.notice("AtaController::inPort: controllerId: {0:d}; ioPortAddr: {1:#06x}; dataSize: {2:d}", self.controllerId, ioPortAddr, dataSize)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef AtaDrive drive
        cdef unsigned char prevReset
        drive = self.drive[self.driveId]
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
                drive = self.drive[self.driveId]
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
                self.main.notice("AtaController::outPort: controllerId: {0:d}; ioPortAddr: {1:#06x}; data: {2:#04x}; dataSize: {3:d}", self.controllerId, ioPortAddr, data, dataSize)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cdef void run(self):
        cdef unsigned char hdaLoaded, hdbLoaded, cmosVal
        if (self.controllerId == 0):
            if (self.main.hdaFilename): (<AtaDrive>self.drive[0]).loadDrive(self.main.hdaFilename)
            if (self.main.hdbFilename): (<AtaDrive>self.drive[1]).loadDrive(self.main.hdbFilename)
            fdaLoaded = (<AtaDrive>self.drive[0]).getIsLoaded()
            fdbLoaded = (<AtaDrive>self.drive[1]).getIsLoaded()
            #cmosVal = (<Cmos>self.main.platform.cmos).readValue(CMOS_EQUIPMENT_BYTE, OP_SIZE_BYTE)
            #if (fdaLoaded or fdbLoaded):
            #    cmosVal |= 0x1
            #    if (fdaLoaded and fdbLoaded):
            #        cmosVal |= 0x40
            #(<Cmos>self.main.platform.cmos).writeValue(CMOS_EQUIPMENT_BYTE, cmosVal, OP_SIZE_BYTE)
            #(<Cmos>self.main.platform.cmos).setEquipmentDefaultValue(cmosVal)


cdef class Ata:
    def __init__(self, object main):
        self.main = main
        self.controller = (AtaController(self, self.main, 0), AtaController(self, self.main, 1))
    cdef void reset(self):
        cdef AtaController controller
        for controller in self.controller:
            controller.reset(False)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (ioPortAddr in ATA1_PORTS and len(self.controller) >= 1 and self.controller[0]):
            return (<AtaController>self.controller[0]).inPort(ioPortAddr-ATA1_BASE, dataSize)
        elif (ioPortAddr in ATA2_PORTS and len(self.controller) >= 2 and self.controller[1]):
            return (<AtaController>self.controller[1]).inPort(ioPortAddr-ATA2_BASE, dataSize)
        elif (ioPortAddr in ATA3_PORTS and len(self.controller) >= 3 and self.controller[2]):
            return (<AtaController>self.controller[2]).inPort(ioPortAddr-ATA3_BASE, dataSize)
        elif (ioPortAddr in ATA4_PORTS and len(self.controller) >= 4 and self.controller[3]):
            return (<AtaController>self.controller[3]).inPort(ioPortAddr-ATA4_BASE, dataSize)
        return BITMASK_BYTE
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (ioPortAddr in ATA1_PORTS and len(self.controller) >= 1 and self.controller[0]):
            (<AtaController>self.controller[0]).outPort(ioPortAddr-ATA1_BASE, data, dataSize)
        elif (ioPortAddr in ATA2_PORTS and len(self.controller) >= 2 and self.controller[1]):
            (<AtaController>self.controller[1]).outPort(ioPortAddr-ATA2_BASE, data, dataSize)
        elif (ioPortAddr in ATA3_PORTS and len(self.controller) >= 3 and self.controller[2]):
            (<AtaController>self.controller[2]).outPort(ioPortAddr-ATA3_BASE, data, dataSize)
        elif (ioPortAddr in ATA4_PORTS and len(self.controller) >= 4 and self.controller[3]):
            (<AtaController>self.controller[3]).outPort(ioPortAddr-ATA4_BASE, data, dataSize)
    cdef void run(self):
        pass


