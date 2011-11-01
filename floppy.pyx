import os

include "globals.pxi"


cdef class FloppyDrive:
    cpdef public object controller, main, fp
    cdef public bytes filename
    cdef public unsigned char driveId, driveType, isLoaded
    def __init__(self, object controller, unsigned char driveId):
        self.controller = controller
        self.main = self.controller.main
        self.driveId = driveId
        self.driveType = FLOPPY_DISK_TYPE_NONE
        self.filename = bytes()
        self.fp = None
        self.isLoaded = False
    cpdef ChsToSector(self, unsigned char cylinder, unsigned char head, unsigned char sector):
        return (cylinder*2*18)+(head*18)+(sector-1) # FIXME: 1.44MB floppy
    cpdef getDiskType(self, unsigned long size):
        cdef unsigned char diskType = FLOPPY_DISK_TYPE_NONE
        if (self.main.forceFloppyDiskType != FLOPPY_DISK_TYPE_NONE):
            diskType = self.main.forceFloppyDiskType
        elif (size == SIZE_360K):
            diskType = FLOPPY_DISK_TYPE_360K
        elif (size == SIZE_1_2M):
            diskType = FLOPPY_DISK_TYPE_1_2M
        elif (size == SIZE_720K):
            diskType = FLOPPY_DISK_TYPE_720K
        elif (size == SIZE_1_44M):
            diskType = FLOPPY_DISK_TYPE_1_44M
        elif (size == SIZE_2_88M):
            diskType = FLOPPY_DISK_TYPE_2_88M
        else:
            self.main.printMsg("FloppyDrive::getDiskType: can't assign filesize {0:d} to a type, mark disk as unrecognized", size)
        return diskType
    cpdef loadDrive(self, bytes filename):
        cdef unsigned char cmosDiskType
        if (not filename or not os.path.exists(filename)):
            self.main.printMsg("FD{0:d}: loadDrive: filename not found. (filename: {1:s})", self.driveId, filename)
            return
        self.filename = filename
        self.driveType = self.getDiskType(os.path.getsize(self.filename))
        if (self.driveType == FLOPPY_DISK_TYPE_NONE):
            self.main.printMsg("FloppyDrive::loadDrive: driveType is DISK_TYPE_NONE")
            return
        self.fp = open(filename, "r+b")
        self.isLoaded = True
        if (self.driveId in (0, 1)):
            cmosDiskType = self.main.platform.cmos.readValue(CMOS_FLOPPY_DRIVE_TYPE, OP_SIZE_BYTE)
            if (self.driveId == 0):
                cmosDiskType &= 0x0f
                cmosDiskType |= (self.driveType&0xf)<<4
            elif (self.driveId == 1):
                cmosDiskType &= 0xf0
                cmosDiskType |= self.driveType&0xf
            self.main.platform.cmos.writeValue(CMOS_FLOPPY_DRIVE_TYPE, cmosDiskType, OP_SIZE_BYTE)
    cpdef readSectors(self, unsigned long sector, unsigned long count): # count in sectors
        cdef bytes retData
        cdef unsigned long oldPos
        oldPos = self.fp.tell()
        self.fp.seek(sector*512)
        retData = self.fp.read(count*512)
        self.fp.seek(oldPos)
        return retData
    cpdef writeSectors(self, unsigned long sector, bytes data):
        cdef unsigned long oldPos
        if (len(data)%512):
            self.main.exitError("FD{0:d}: writeSectors: datalength invalid. (sector: {1:d}, datalength: {2:d})", self.driveId, sector, len(data))
            return
        oldPos = self.fp.tell()
        self.fp.seek(sector*512)
        retData = self.fp.write(data)
        self.fp.seek(oldPos)
    

cdef class FloppyController:
    cpdef public object floppy, main, fdcDma
    cdef unsigned char msr, dor, st0, st1, st2, st3, tc
    cdef bytes command, result, sectorData
    cpdef dict cmdLengthTable
    cdef public tuple drive
    cdef public unsigned char controllerId
    def __init__(self, object floppy, unsigned char controllerId):
        self.floppy = floppy
        self.main = self.floppy.main
        self.fdcDma = self.main.platform.isadma.controller[0].channel[FDC_DMA_CHANNEL]
        self.controllerId = controllerId
        self.drive = (FloppyDrive(self, 0), FloppyDrive(self, 1), FloppyDrive(self, 2), FloppyDrive(self, 3))
        self.cmdLengthTable = {0x2: 9, 0x3: 3, 0x4: 2, 0x5: 9, 0x6: 9, 0x7: 2, 0x8: 1, 0xf: 3 }
        self.reset(True)
    cpdef reset(self, unsigned char hwReset):
        self.msr = self.st0 = self.st1 = self.st2 = self.st3 = 0
        self.tc = False
        self.command = self.result = self.sectorData = bytes()
        if (hwReset):
            self.dor = FDC_DOR_IRQ | FDC_DOR_RST
        self.floppy.lowerFloppyIrq()
        if (not (self.msr & FDC_MSR_NDMA)):
            self.main.platform.isadma.setDRQ(FDC_DMA_CHANNEL, False)
        self.handleIdle()
        
        
            self.st0 = 0xc0
            if (self.tc):
                self.floppy.raiseFloppyIrq()
        
    cpdef addToCommand(self, unsigned char command):
        cdef unsigned char cmdLength
        self.clearResult()
        self.command += bytes([command])
        cmdLength = self.cmdLengthTable.get(self.command[0]&0x1f)
        if (not cmdLength):
            self.main.exitError("FDC: addToCommand: invalid command")
            return
        if (cmdLength == len(self.command)):
            self.msr |= FDC_MSR_BUSY
            self.handleCommand()
            self.msr &= ~FDC_MSR_BUSY
    cpdef addToResult(self, unsigned char result):
        self.result += bytes([result])
    cpdef clearCommand(self):
        self.command = bytes()
    cpdef clearResult(self):
        self.result = bytes()
    cpdef setDor(self, unsigned char data):
        cdef unsigned char drive = data & 3
        self.dor = data
        if (not (data & FDC_DOR_RST)):
            self.clearCommand()
            self.reset(False)
        elif (not (data & 0x8)):
            self.main.exitError("FDC: outPort_setDor: just DMA is supported yet. (data: {0:#04x})", data)
            return
    cpdef setMsr(self, unsigned char data):
        self.msr = data
    cpdef handleIdle(self):
        self.msr &= FDC_MSR_NDMA | 0xf
        self.msr |= FDC_MSR_MRQ
        self.command = self.sectorData = bytes()
    cpdef handleCommand(self):
        cdef unsigned char drive, cmd
        drive = self.dor
        cmd = self.command[0]&0x1f
        self.msr |= FDC_MSR_MRQ | FDC_MSR_DIO | FDC_MSR_BUSY
        if (cmd == 0x3): # set drive parameters
            if (self.command[2] & 0x1): # NO DMA
                self.main.exitError("FDC: handleCommand 0x3: just DMA is supported yet.")
                return
        elif (cmd == 0x4): # check drive state
            self.st3 = FDC_ST3_RDY | FDC_ST3_DSDR | self.command[1]&7
            self.addToResult(self.st3)
        elif (cmd in (0x7, 0xf)): # 0x7: calibrate drive ## 0xf: positioning r/w head
            self.floppy.raiseFloppyIrq()
            self.st0 = FDC_ST0_SE | self.command[1]&7
        elif (cmd == 0x8): # check interrupt state
            self.addToResult(self.st0)
            self.addToResult(0)
        elif (cmd in (0x2,0x5,0x6)): # 0x2: read track/0x5: write sector/0x6: read sector
            if (not (self.command[0] & 0x40)):
                self.main.exitError("FDC: handleCommand 0x2/0x5/0x6: not (self.command[0]:{0:#04x} & 0x40)", self.command[0])
                return
            if (not (self.command[0] & 0x20)):
                self.main.exitError("FDC: handleCommand 0x2/0x5/0x6: not (self.command[0]:{0:#04x} & 0x20)", self.command[0])
                return
            if (self.command[5] != 2 or self.command[8] != 0xff):
                self.main.exitError("FDC: handleCommand 0x2/0x5/0x6: cmd[5]:{0:d} != 2 OR cmd[8]:{1:#04x} != 0xff", self.command[5], self.command[8])
                return
            if (not self.command[4] or not self.command[6]):
                self.main.exitError("FDC: handleCommand 0x2/0x5/0x6: cmd[4]:{0:d} == 0 OR cmd[6]:{1:d} == 0. (sectors can't be 0)", self.command[5], self.command[7])
                return
            head = self.command[3]
            if ((self.command[1]&7)>>2 != head):
                self.main.exitError("FDC: handleCommand 0x2/0x5/0x6: cmd[1]:{0:d} head ISN'T cmd[3]:{1:d}", self.command[1], head)
                return
            cylinder = self.command[2]
            sector = self.command[4]
            lastSector = self.command[6]
            realSector = self.drive[drive].ChsToSector(cylinder, head, sector)
            realEndSector = self.drive[drive].ChsToSector(cylinder, head, lastSector)
            if (cmd in (0x2, 0x6)): # read
                self.sectorData = self.drive[drive].readSectors(realSector, realEndSector-realSector+1)
                self.doDMATransfer()
                self.msr = 0xc0
                self.st0 = ((head&1)<<2) | self.command[1]&7
                self.st3 = FDC_ST3_RDY | FDC_ST3_DSDR | ((head&1)<<2) | self.command[1]&7
                self.addToResult(self.st0)
                self.addToResult(self.st1)
                self.addToResult(self.st2)
                self.addToResult(cylinder)
                self.addToResult(head)
                self.addToResult(sector)
                self.addToResult(2)
                self.floppy.raiseFloppyIrq()
            else:
                self.main.exitError("FDC: handleCommand 0x5: write not implemented yet.")
        self.clearCommand()
    cpdef doDMATransfer(self):
        self.fdcDma.dmaReadFromMem = self.writeToDrive
        self.fdcDma.dmaWriteToMem = self.readFromDrive
        self.main.platform.isadma.raiseHLDA()
    cpdef writeToDrive(self, unsigned char *data):
        self.main.exitError("FDC::writeToDrive: not implemented yet!")
    cpdef readFromDrive(self, unsigned char *data):
        *data = self.sectorData[0]
        self.sectorData = self.sectorData[1:]
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char retVal = 0
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x2): # read dor
                retVal = self.dor
            elif (ioPortAddr == 0x3): # tape drive register
                pass
            elif (ioPortAddr == 0x4): # read msr
                if (len(self.result)):
                    self.msr |= FDC_MSR_DIO
                else:
                    self.msr &= ~FDC_MSR_DIO
                retVal = self.msr
            elif (ioPortAddr == 0x5):
                if ((self.msr & FDC_MSR_NDMA) and (len(self.command) > 0 and (self.command[0] & 0x4f) == 0x46)):
                    if ():
                        self.floppy.lowerFloppyIrq()
                elif (not len(self.result)):
                    return 0
                else:
                    retVal = self.result[0]
                    self.result = self.result[1:]
                    self.msr &= 0xf0
                    self.floppy.lowerFloppyIrq()
                    if (not len(self.result)):
                        self.handleIdle()
            elif (ioPortAddr == 0x6):
                return 0x00 # TODO: 0x3f6/0x376 should be shared with hard disk controller.
                ##self.main.printMsg("FDC_CTRL::inPort: reserved read from port {0:#06x}. (dataSize byte)", ioPortAddr)
            else:
                self.main.printMsg("FDC_CTRL::inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("FDC_CTRL::inPort: dataSize {0:d} not supported.", dataSize)
        return retVal
    cpdef outPort(self, unsigned short ioPortAddr, unsigned char data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x2): # set dor
                self.setDor(data)
            elif (ioPortAddr == 0x5): # send cmds
                self.addToCommand(data)
            elif (ioPortAddr == 0x6):
                return # TODO: 0x3f6/0x376 should be shared with hard disk controller.
                ##self.main.printMsg("FDC_CTRL::outPort: reserved write to port {0:#06x}. (dataSize byte, data {1:#04x})", ioPortAddr, data)
            else:
                self.main.printMsg("FDC_CTRL::outPort: port {0:#06x} not supported. (dataSize byte, data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("FDC_CTRL::outPort: dataSize {0:d} not supported.", dataSize)

cdef class Floppy:
    cpdef public object main
    cpdef unsigned char msr, dor, st0, st1, st2, st3
    cpdef bytes command, result
    cpdef dict cmdLengthTable
    cpdef tuple readPortsFirstFDC, readPortsSecondFDC, writePortsFirstFDC, writePortsSecondFDC
    cpdef public tuple controller
    def __init__(self, object main):
        self.main = main
        self.controller = (FloppyController(self, 0), FloppyController(self, 1))
        self.readPortsFirstFDC = (0x3f0, 0x3f1, 0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f6, 0x3f7)
        self.readPortsSecondFDC = (0x370, 0x371, 0x372, 0x373, 0x374, 0x375, 0x376, 0x377)
        self.writePortsFirstFDC = (0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f6, 0x3f7)
        self.writePortsSecondFDC = (0x372, 0x373, 0x374, 0x375, 0x376, 0x377)
    cpdef raiseFloppyIrq(self):
        self.main.platform.pic.raiseIrq(FDC_IRQ)
    cpdef lowerFloppyIrq(self):
        self.main.platform.pic.lowerIrq(FDC_IRQ)
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr >= FDC_FIRST_PORTBASE and ioPortAddr <= FDC_FIRST_PORTBASE+FDC_PORTCOUNT):
                return self.controller[0].inPort(ioPortAddr-FDC_FIRST_PORTBASE, dataSize)
            elif (ioPortAddr >= FDC_SECOND_PORTBASE and ioPortAddr <= FDC_SECOND_PORTBASE+FDC_PORTCOUNT):
                return self.controller[1].inPort(ioPortAddr-FDC_SECOND_PORTBASE, dataSize)
            else:
                self.main.printMsg("inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cpdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr >= FDC_FIRST_PORTBASE and ioPortAddr <= FDC_FIRST_PORTBASE+FDC_PORTCOUNT):
                self.controller[0].outPort(ioPortAddr-FDC_FIRST_PORTBASE, data, dataSize)
            elif (ioPortAddr >= FDC_SECOND_PORTBASE and ioPortAddr <= FDC_SECOND_PORTBASE+FDC_PORTCOUNT):
                self.controller[1].outPort(ioPortAddr-FDC_SECOND_PORTBASE, data, dataSize)
            else:
                self.main.printMsg("inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cpdef run(self):
        if (self.main.fdaFilename):
            self.controller[0].drive[0].loadDrive(self.main.fdaFilename)
        if (self.main.fdbFilename):
            self.controller[0].drive[1].loadDrive(self.main.fdbFilename)
        self.main.platform.addReadHandlers(self.readPortsFirstFDC, self)
        self.main.platform.addReadHandlers(self.readPortsSecondFDC, self)
        self.main.platform.addWriteHandlers(self.writePortsFirstFDC, self)
        self.main.platform.addWriteHandlers(self.writePortsSecondFDC, self)








