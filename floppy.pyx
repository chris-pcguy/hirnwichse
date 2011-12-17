import os

# This file contains (much) code from the Bochs Emulator (c) by it's developers


include "globals.pxi"



cdef class FloppyMedia:
    def __init__(self, FloppyDrive floppyDrive):
        self.floppyDrive = floppyDrive
        self.mediaType = FLOPPY_DISK_TYPE_NONE
        self.tracks = self.heads = self.sectorsPerTrack = self.sectors = 0
    cdef setDataForMedia(self, unsigned char mediaType):
        self.mediaType = mediaType
        if (mediaType == FLOPPY_DISK_TYPE_NONE):
            self.tracks = self.heads = self.sectorsPerTrack = self.sectors = 0
        elif (mediaType in (FLOPPY_DISK_TYPE_360K, FLOPPY_DISK_TYPE_1_2M, FLOPPY_DISK_TYPE_720K, \
           FLOPPY_DISK_TYPE_1_44M, FLOPPY_DISK_TYPE_2_88M)):
            self.heads = 2
            if (mediaType == FLOPPY_DISK_TYPE_360K):
                self.tracks = 40
                self.sectorsPerTrack = 9
                self.sectors = 720
            else:
                self.tracks = 80
            if (mediaType == FLOPPY_DISK_TYPE_720K):
                self.sectorsPerTrack = 9
                self.sectors = 1440
            elif (mediaType == FLOPPY_DISK_TYPE_1_2M):
                self.sectorsPerTrack = 15
                self.sectors = 2400
            elif (mediaType == FLOPPY_DISK_TYPE_1_44M):
                self.sectorsPerTrack = 18
                self.sectors = 2880
            elif (mediaType == FLOPPY_DISK_TYPE_2_88M):
                self.sectorsPerTrack = 36
                self.sectors = 5760
        else:
            self.floppyDrive.main.exitError("FloppyMedia::setDataForMedia: unknown mediaType {0:d}", mediaType)


cdef class FloppyDrive:
    def __init__(self, FloppyController controller, unsigned char driveId):
        self.controller = controller
        self.main = self.controller.main
        self.driveId = driveId
        self.media = FloppyMedia(self)
        self.filename = b""
        self.fp = None
        self.isLoaded = False
        self.isWriteProtected = True
        self.DIR = 0
        self.cylinder = self.head = self.sector = self.eot = 0
    cdef unsigned long ChsToSector(self, unsigned char cylinder, unsigned char head, unsigned char sector):
        return (cylinder*self.media.heads*self.media.sectorsPerTrack)+(head*self.media.sectorsPerTrack)+(sector-1)
    cdef unsigned char getDiskType(self, unsigned long size):
        cdef unsigned char diskType = FLOPPY_DISK_TYPE_NONE
        if (self.main.forceFloppyDiskType != FLOPPY_DISK_TYPE_NONE):
            diskType = self.main.forceFloppyDiskType
        elif (size <= SIZE_360K):
            diskType = FLOPPY_DISK_TYPE_360K
        elif (size <= SIZE_720K):
            diskType = FLOPPY_DISK_TYPE_720K
        elif (size <= SIZE_1_2M):
            diskType = FLOPPY_DISK_TYPE_1_2M
        elif (size <= SIZE_1_44M):
            diskType = FLOPPY_DISK_TYPE_1_44M
        elif (size <= SIZE_2_88M):
            diskType = FLOPPY_DISK_TYPE_2_88M
        else:
            self.main.printMsg("FloppyDrive::getDiskType: can't assign filesize {0:d} to a type, mark disk as unrecognized", size)
        self.main.printMsg("FloppyDrive::getDiskType: floppy has disktype {0:d}.", diskType)
        return diskType
    cdef loadDrive(self, bytes filename):
        cdef unsigned char cmosDiskType, driveType
        if (not filename or not os.path.exists(filename)):
            self.main.printMsg("FD{0:d}: loadDrive: filename not found. (filename: {1:s})", self.driveId, filename)
            return
        self.filename = filename
        driveType = self.getDiskType(os.path.getsize(self.filename))
        self.media.setDataForMedia(driveType)
        if (driveType == FLOPPY_DISK_TYPE_NONE):
            self.main.printMsg("FloppyDrive::loadDrive: driveType is DISK_TYPE_NONE")
            return
        self.fp = open(filename, "r+b")
        self.isLoaded = True
        if (self.driveId in (0, 1) and self.controller.fdc.cmos is not None):
            cmosDiskType = self.controller.fdc.cmos.readValue(CMOS_FLOPPY_DRIVE_TYPE, OP_SIZE_BYTE)
            if (self.driveId == 0):
                cmosDiskType &= 0x0f
                cmosDiskType |= (driveType&0xf)<<4
            elif (self.driveId == 1):
                cmosDiskType &= 0xf0
                cmosDiskType |= driveType&0xf
            self.controller.fdc.cmos.writeValue(CMOS_FLOPPY_DRIVE_TYPE, cmosDiskType, OP_SIZE_BYTE)
    cdef bytes readBytes(self, unsigned long offset, unsigned long size):
        cdef bytes data
        cdef unsigned long oldPos
        oldPos = self.fp.tell()
        self.fp.seek(offset)
        data = self.fp.read(size)
        if (len(data) < size): # floppy image is too short.
            data += b'\x00'*(size-len(data))
        self.fp.seek(oldPos)
        return data
    cdef bytes readSectors(self, unsigned long sector, unsigned long count): # count in sectors
        return self.readBytes(sector*512, count*512)
    cdef writeSectors(self, unsigned long sector, bytes data):
        cdef unsigned long oldPos
        if (len(data)%512):
            self.main.exitError("FD{0:d}: writeSectors: datalength invalid. (sector: {1:d}, datalength: {2:d})", self.driveId, sector, len(data))
            return
        oldPos = self.fp.tell()
        self.fp.seek(sector*512)
        retData = self.fp.write(data)
        self.fp.seek(oldPos)


cdef class FloppyController:
    def __init__(self, Floppy fdc, unsigned char controllerId):
        self.fdc = fdc
        self.main = self.fdc.main
        self.controllerId = controllerId
        self.drive = (FloppyDrive(self, 0), FloppyDrive(self, 1), FloppyDrive(self, 2), FloppyDrive(self, 3))
        self.fdcBufferIndex = 0
        self.command = self.result = self.fdcBuffer = b""
    cdef reset(self, unsigned char hwReset):
        cdef unsigned char i
        self.resetSensei = self.msr = self.st0 = self.st1 = self.st2 = self.st3 = 0
        self.pendingIrq = False
        self.fdc.setupDMATransfer(self)
        if (hwReset):
            self.DOR = FDC_DOR_NORESET | FDC_DOR_DMA
            self.dataRate = 2
        for i in range(4):
            if (hwReset):
                (<FloppyDrive>self.drive[i]).DIR |= 0x80
            (<FloppyDrive>self.drive[i]).cylinder = (<FloppyDrive>self.drive[i]).head = (<FloppyDrive>self.drive[i]).sector = (<FloppyDrive>self.drive[i]).eot = 0
        self.lowerFloppyIrq()
        if (not (self.msr & FDC_MSR_NODMA) and self.fdc.isaDma is not None):
            (<IsaDma>self.fdc.isaDma).setDRQ(FDC_DMA_CHANNEL, False)
        self.handleIdle()
    cdef bytes floppyXfer(self, unsigned char drive, unsigned long offset, unsigned long size, unsigned char toFloppy):
        if (toFloppy):
            self.main.exitError("FDC_CTRL::floppyXfer: write to floppy isn't supported yet.")
            return
        return (<FloppyDrive>self.drive[drive]).readBytes(offset, size)
    cdef addCommand(self, unsigned char command):
        cdef unsigned char cmdLength = 0
        if (len(self.command) == 0):
            self.msr &= ~FDC_MSR_DIO
            self.msr |= (FDC_MSR_RQM | FDC_MSR_BUSY)
        self.addToCommand(command)
        if (FDC_CMDLENGTH_TABLE.get(self.command[0])):
            cmdLength = FDC_CMDLENGTH_TABLE.get(self.command[0])
        if (not cmdLength):
            self.main.exitError("FDC: addCommand: invalid command: {0:#04x}", self.command[0])
            return
        elif ((self.msr & FDC_MSR_NODMA) and ((self.command[0] & 0x4f) == 0x45)):
            self.writeToDrive(command)
            self.lowerFloppyIrq()
            return
        if (len(self.command) == cmdLength):
            self.handleCommand()
            return
        elif (len(self.command) > cmdLength):
            self.main.exitError("FDC: addCommand: command {0:#04x} too long (current length: {1:d}, correct length: {2:d}).", self.command[0], len(self.command), cmdLength)
            return
    cdef addToCommand(self, unsigned char command):
        self.command += bytes([command])
    cdef addToResult(self, unsigned char result):
        self.result += bytes([result])
    cdef clearCommand(self):
        self.command = b""
    cdef clearResult(self):
        self.result = b""
    cdef setDor(self, unsigned char data):
        cdef unsigned char normalOperation, prevNormalOperation
        normalOperation = data & 0x4
        prevNormalOperation = self.DOR & 0x4
        self.DOR = data
        #if (not prevNormalOperation and normalOperation): # reset -> normal
        #    pass
        #el
        if (prevNormalOperation and not normalOperation): # normal -> reset
            self.msr &= FDC_MSR_NODMA
            self.doCmdReset()
    cdef setMsr(self, unsigned char data):
        self.msr = data
    cdef doCmdReset(self):
        self.reset(False)
        self.clearCommand()
        self.st0 = 0xc0
        self.raiseFloppyIrq()
        self.resetSensei = 4
    cdef resetChangeline(self):
        cdef unsigned char drive
        drive = self.DOR & 0x3
        if ((<FloppyDrive>self.drive[drive]).isLoaded):
            (<FloppyDrive>self.drive[drive]).DIR &= ~0x80
    cdef incrementSector(self):
        cdef unsigned char drive
        drive = self.DOR & 0x3
        (<FloppyDrive>self.drive[drive]).sector += 1
        if ( ((<FloppyDrive>self.drive[drive]).sector > (<FloppyDrive>self.drive[drive]).eot) or \
             ((<FloppyDrive>self.drive[drive]).sector > (<FloppyDrive>self.drive[drive]).media.sectorsPerTrack) ):
            (<FloppyDrive>self.drive[drive]).sector = 1
            if (self.multiTrack):
                (<FloppyDrive>self.drive[drive]).head += 1
                if ((<FloppyDrive>self.drive[drive]).head > 1):
                    (<FloppyDrive>self.drive[drive]).head = 0
                    (<FloppyDrive>self.drive[drive]).cylinder += 1
                    self.resetChangeline()
            else:
                (<FloppyDrive>self.drive[drive]).cylinder += 1
                self.resetChangeline()
            if ((<FloppyDrive>self.drive[drive]).cylinder >= (<FloppyDrive>self.drive[drive]).media.tracks):
                (<FloppyDrive>self.drive[drive]).cylinder = (<FloppyDrive>self.drive[drive]).media.tracks
    cdef getTC(self):
        cdef unsigned char drive, TC
        self.fdc.setupDMATransfer(self)
        TC = False
        if (self.msr & FDC_MSR_NODMA):
            drive = self.DOR & 0x3
            TC = ((self.fdcBufferIndex == 512) and ((<FloppyDrive>self.drive[drive]).sector == (<FloppyDrive>self.drive[drive]).eot) and \
                  ((<FloppyDrive>self.drive[drive]).head == ((<FloppyDrive>self.drive[drive]).media.heads-1)))
        else:
            if (self.fdc.isaDma is not None):
                TC = (<IsaDma>self.fdc.isaDma).getTC()
        return TC
    cdef handleResult(self):
        cdef unsigned char drive
        drive = self.DOR & 0x3
        self.clearResult()
        self.msr |= (FDC_MSR_RQM | FDC_MSR_DIO | FDC_MSR_BUSY)

        if ((self.st0 & 0xc0) == 0x80):
            self.addToResult(self.st0)
            return

        if (len(self.command) > 0):
            if (self.command[0] == 0x4):
                self.addToResult(self.st3)
            elif (self.command[0] == 0x8):
                self.addToResult(self.st0)
                self.addToResult((<FloppyDrive>self.drive[drive]).cylinder)
            elif (self.command[0] in (0x4a, 0x4d, 0x46, 0x66, 0xc6, 0xe6, 0x45, 0xc5)):
                self.addToResult(self.st0)
                self.addToResult(self.st1)
                self.addToResult(self.st2)
                self.addToResult((<FloppyDrive>self.drive[drive]).cylinder)
                self.addToResult((<FloppyDrive>self.drive[drive]).head)
                self.addToResult((<FloppyDrive>self.drive[drive]).sector)
                self.addToResult(2)
                self.raiseFloppyIrq()
            else:
                self.main.exitError("FDC_CTRL::handleResult: unknown command: {0:#04x}", self.command[0])
        else:
            self.main.exitError("FDC_CTRL::handleResult: self.command is empty.")
    cdef handleIdle(self):
        self.msr &= (FDC_MSR_NODMA | 0xf)
        self.msr |= FDC_MSR_RQM
        self.clearCommand()
        self.fdcBufferIndex = 0
    cdef handleCommand(self):
        cdef unsigned char drive, cmd, motorOn, head, cylinder, sector, eot, sectorSize
        cdef unsigned long logicalSector
        cmd = self.command[0]
        self.msr |= FDC_MSR_RQM | FDC_MSR_DIO | FDC_MSR_BUSY
        self.fdc.setupDMATransfer(self)
        if (cmd == 0x3): # set drive parameters
            if (self.command[2] & 0x1):
                self.msr |= FDC_MSR_NODMA
            if (self.msr & FDC_MSR_NODMA): # NO DMA
                self.main.exitError("FDC: handleCommand 0x3: PIO mode isn't fully supported yet.")
                return
            self.handleIdle()
            return
        elif (cmd == 0x4): # check drive state
            drive = self.command[1] & 0x3
            (<FloppyDrive>self.drive[drive]).head = (self.command[1] >> 2) & 0x1
            #self.st3 = FDC_ST3_RDY | FDC_ST3_DSDR | self.command[1]&7
            self.st3 = FDC_ST3_RDY | FDC_ST3_DSDR | ((<FloppyDrive>self.drive[drive]).head << 2) | drive
            if ((<FloppyDrive>self.drive[drive]).isWriteProtected):
                self.st3 |= FDC_ST3_WPDR
            if ((<FloppyDrive>self.drive[drive]).media.mediaType != FLOPPY_DISK_TYPE_NONE and (<FloppyDrive>self.drive[drive]).cylinder == 0):
                self.st3 |= FDC_ST3_TRKO
            self.handleResult()
            return
        elif (cmd in (0x7, 0xf)): # 0x7: calibrate drive ## 0xf: positioning r/w head
            drive = self.command[1] & 0x3
            self.DOR &= 0xfc
            self.DOR |= drive
            if (cmd == 0x7):
                (<FloppyDrive>self.drive[drive]).cylinder = 0
            else:
                (<FloppyDrive>self.drive[drive]).head = (self.command[1] >> 2) & 0x1
                (<FloppyDrive>self.drive[drive]).cylinder = self.command[2]
            self.msr &= FDC_MSR_NODMA
            self.msr |= (1 << drive)
            if (cmd == 0x7):
                self.st0 = FDC_ST0_SE | drive
                if ((<FloppyDrive>self.drive[drive]).media.mediaType == FLOPPY_DISK_TYPE_NONE or not ((self.DOR >> (drive+4)) & 0x1)):
                    self.st0 |= 0x50
            else:
                self.st0 = FDC_ST0_SE | ((<FloppyDrive>self.drive[drive]).head << 2) | drive
            self.handleIdle()
            self.raiseFloppyIrq()
        elif (cmd == 0x8): # check interrupt state
            if (self.resetSensei):
                drive = 4 - self.resetSensei
                self.st0 &= 0xf8
                self.st0 |= ((<FloppyDrive>self.drive[drive]).head << 2) | drive
                self.resetSensei -= 1
            elif (not self.pendingIrq):
                self.st0 = 0x80
            self.handleResult()
            return
        elif (cmd == 0x4a): # read id
            drive = self.command[1] & 0x3
            (<FloppyDrive>self.drive[drive]).head = (self.command[1] >> 2) & 0x1
            self.DOR &= 0xfc
            self.DOR |= drive
            motorOn = (self.DOR >> (drive+4)) & 0x1
            if (not motorOn or (<FloppyDrive>self.drive[drive]).media.mediaType == FLOPPY_DISK_TYPE_NONE or not (<FloppyDrive>self.drive[drive]).isLoaded):
                self.msr &= FDC_MSR_NODMA
                self.msr |= FDC_MSR_BUSY
                return
            self.st0 = ((<FloppyDrive>self.drive[drive]).head << 2) | drive
            self.msr &= FDC_MSR_NODMA
            self.msr |= FDC_MSR_BUSY
            self.handleResult()
            return
        elif (cmd in (0x46, 0x66, 0xc6, 0xe6, 0x45, 0xc5)):
            self.multiTrack = (cmd >> 7) != 0
            if (not (self.DOR & 0x8)):
                self.main.exitError("FDC: read/write command with DMA and INT disabled.")
                return
            drive = self.command[1] & 0x3
            self.DOR &= 0xfc
            self.DOR |= drive
            motorOn = (self.DOR >> (drive+4)) & 0x1
            if (not motorOn):
                self.main.exitError("FDC: read/write: motor not on.")
                return
            head = self.command[3] & 0x1
            cylinder = self.command[2]
            sector = self.command[4]
            eot = self.command[6]
            sectorSize = self.command[5]
            if ((<FloppyDrive>self.drive[drive]).media.mediaType == FLOPPY_DISK_TYPE_NONE):
                self.main.exitError("FDC: read/write: bad drive #{0:d}", drive)
                return
            if (head != ((self.command[1] >> 2) & 0x1)):
                self.main.printMsg("FDC ERROR: head number in command[1] doesn't match head field.")
                self.st0 = 0x40 | ((<FloppyDrive>self.drive[drive]).head << 2) | drive
                self.st1 = 0x04
                self.st2 = 0x00
                self.handleResult()
                return

            if (not (<FloppyDrive>self.drive[drive]).isLoaded):
                return

            if (sectorSize != 0x2):
                self.main.exitError("FDC: read/write: sector size {0:d} isn't supported.", (128 << sectorSize))
                return

            if (cylinder >= (<FloppyDrive>self.drive[drive]).media.tracks):
                self.main.exitError("FDC: read/write: params out of range: sec#{0:d}, cyl#{1:d}, eot#{2:d}, head#{3:d}.", sector, cylinder, eot, head)
                return

            if (sector > (<FloppyDrive>self.drive[drive]).media.sectorsPerTrack):
                self.main.printMsg("FDC: attempt to read/write sector {0:d} past last sector {1:d}.", sector, (<FloppyDrive>self.drive[drive]).media.sectorsPerTrack)
                (<FloppyDrive>self.drive[drive]).cylinder = cylinder
                (<FloppyDrive>self.drive[drive]).head = head
                (<FloppyDrive>self.drive[drive]).sector = sector
                self.st0 = 0x40 | ((<FloppyDrive>self.drive[drive]).head << 2) | drive
                self.st1 = 0x04
                self.st2 = 0x00
                self.handleResult()
                return

            if (cylinder != (<FloppyDrive>self.drive[drive]).cylinder):
                self.resetChangeline()

            logicalSector = (<FloppyDrive>self.drive[drive]).ChsToSector(cylinder, head, sector)

            if (logicalSector >= (<FloppyDrive>self.drive[drive]).media.sectors):
                self.main.exitError("FDC: logical sector out of bounds")
                return

            (<FloppyDrive>self.drive[drive]).cylinder = cylinder
            (<FloppyDrive>self.drive[drive]).head = head
            (<FloppyDrive>self.drive[drive]).sector = sector
            (<FloppyDrive>self.drive[drive]).eot = eot

            if ((cmd & 0xf) == 0x6): # read
                self.fdcBuffer = self.floppyXfer(drive, logicalSector*FDC_SECTOR_SIZE, FDC_SECTOR_SIZE, False)
                if (self.msr & FDC_MSR_NODMA):
                    self.msr &= ~FDC_MSR_BUSY
                    self.msr |= (FDC_MSR_RQM | FDC_MSR_DIO)
                else:
                    if (self.fdc.isaDma is not None):
                        (<IsaDma>self.fdc.isaDma).setDRQ(FDC_DMA_CHANNEL, True)
            elif ((cmd & 0xf) == 0x5): # write
                self.main.exitError("FDC: handleCommand 0x5: write not implemented yet.")
            else:
                self.main.exitError("FDC: handleCommand: unknown r/w cmd {0:#04x}.", cmd)
        else:
            self.main.printMsg("FDC: handleCommand: unknown command {0:#04x}.", self.command[0])
            self.clearCommand()
            self.st0 = 0x80
            self.handleResult()
    cdef writeToDrive(self, unsigned char data):
        self.main.exitError("FDC::writeToDrive: not implemented yet!")
    cdef unsigned char readFromDrive(self):
        cdef unsigned char drive, data
        cdef unsigned long logicalSector
        drive = self.DOR & 0x3
        data = self.fdcBuffer[self.fdcBufferIndex]
        self.fdcBufferIndex += 1
        self.TC = self.getTC()
        if (self.fdcBufferIndex >= 512 or self.TC):
            #self.main.printMsg("FDC::readFromDrive: condition: (fdcBufferIndex >= 512 || TC) is TRUE. (fdcBufferIndex: {0:d}, TC: {1:d})", self.fdcBufferIndex, self.TC)
            if (self.fdcBufferIndex >= 512):
                self.incrementSector()
                self.fdcBufferIndex = 0
            if (self.TC):
                self.st0 = ((<FloppyDrive>self.drive[drive]).head << 2) | drive
                self.st1 = self.st2 = 0
                if (not (self.msr & FDC_MSR_NODMA) and self.fdc.isaDma is not None):
                    (<IsaDma>self.fdc.isaDma).setDRQ(FDC_DMA_CHANNEL, False)
                self.handleResult()
            else:
                logicalSector = (<FloppyDrive>self.drive[drive]).ChsToSector((<FloppyDrive>self.drive[drive]).cylinder, (<FloppyDrive>self.drive[drive]).head, (<FloppyDrive>self.drive[drive]).sector)
                self.fdcBuffer = self.floppyXfer(drive, logicalSector*FDC_SECTOR_SIZE, FDC_SECTOR_SIZE, False)
                if (self.msr & FDC_MSR_NODMA):
                    self.msr &= ~FDC_MSR_BUSY
                    self.msr |= (FDC_MSR_RQM | FDC_MSR_DIO)
                elif (self.fdc.isaDma is not None):
                    (<IsaDma>self.fdc.isaDma).setDRQ(FDC_DMA_CHANNEL, True)
        return data
    cdef raiseFloppyIrq(self):
        if (self.fdc.pic is not None):
            self.fdc.pic.raiseIrq(FDC_IRQ)
            self.pendingIrq = True
            self.resetSensei = 0
    cdef lowerFloppyIrq(self):
        if (self.pendingIrq and self.fdc.pic is not None):
            self.fdc.pic.lowerIrq(FDC_IRQ)
            self.pendingIrq = False
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef char retVal, drive
        retVal = 0
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x2): # read dor
                return self.DOR
            elif (ioPortAddr == 0x3): # tape drive register
                drive = self.DOR & 0x3
                if ((<FloppyDrive>self.drive[drive]).isLoaded and (<FloppyDrive>self.drive[drive]).media.mediaType != FLOPPY_DISK_TYPE_NONE):
                    if ((<FloppyDrive>self.drive[drive]).media.mediaType in (FLOPPY_DISK_TYPE_360K, FLOPPY_DISK_TYPE_1_2M)):
                        return 0x00
                    elif ((<FloppyDrive>self.drive[drive]).media.mediaType == FLOPPY_DISK_TYPE_720K):
                        return 0xc0
                    elif ((<FloppyDrive>self.drive[drive]).media.mediaType == FLOPPY_DISK_TYPE_1_44M):
                        return 0x80
                    elif ((<FloppyDrive>self.drive[drive]).media.mediaType == FLOPPY_DISK_TYPE_2_88M):
                        return 0x40
                    else:
                        self.main.exitError("FDC_CTRL::inPort: mediaType {0:d} is unknown.", (<FloppyDrive>self.drive[drive]).media.mediaType)
                        return 0x20
                else:
                    return 0x20
            elif (ioPortAddr == 0x4): # read msr
                return self.msr
            elif (ioPortAddr == 0x5):
                if ((not (self.msr & FDC_MSR_RQM)) or (not (self.msr & FDC_MSR_DIO))):
                    self.main.debug("FDC_CTRL::inPort: controller not ready for reading")
                    return 0
                if ((self.msr & FDC_MSR_NODMA) and (len(self.command) > 0 and (self.command[0] & 0x4f) == 0x46)):
                    retVal = self.readFromDrive()
                    self.lowerFloppyIrq()
                    if (self.TC):
                        self.handleIdle()
                    return retVal
                elif (not len(self.result)):
                    self.msr &= FDC_MSR_NODMA
                    return 0
                else:
                    retVal = self.result[0]
                    if (len(self.result) > 1):
                        self.result = self.result[1:]
                    else:
                        self.clearResult()
                    self.msr &= 0xf0
                    self.lowerFloppyIrq()
                    if (not len(self.result)):
                        self.handleIdle()
                    return retVal
            elif (ioPortAddr == 0x6):
                return 0x00 # TODO: 0x3f6/0x376 should be shared with hard disk controller.
                ##self.main.printMsg("FDC_CTRL::inPort: reserved read from port {0:#06x}. (dataSize byte)", ioPortAddr)
            elif (ioPortAddr == 0x7):
                drive = self.DOR & 0x3
                if (self.DOR & (1<<(drive+4))):
                    return ((<FloppyDrive>self.drive[drive]).DIR & 0x80)
                return 0
            else:
                self.main.printMsg("FDC_CTRL::inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("FDC_CTRL::inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x2): # set dor
                self.setDor(data)
                return
            elif (ioPortAddr == 0x4): # set data rate
                self.dataRate = data & 0x3
                if (data & 0x80):
                    self.msr &= FDC_MSR_NODMA
                    self.doCmdReset()
                if (data & 0x7c):
                    self.main.exitError("FDC_CTRL::outPort: write to data rate select register: unsupported bits set.")
                return
            elif (ioPortAddr == 0x5): # send cmds
                if ((self.msr & FDC_MSR_NODMA) and (len(self.command) > 0 and (self.command[0] & 0x4f) == 0x45)):
                    self.writeToDrive(data)
                    self.lowerFloppyIrq()
                    return
                else:
                    self.addCommand(data)
                return
            elif (ioPortAddr == 0x6):
                return # TODO: 0x3f6/0x376 should be shared with hard disk controller.
                ##self.main.printMsg("FDC_CTRL::outPort: reserved write to port {0:#06x}. (dataSize byte, data {1:#04x})", ioPortAddr, data)
            elif (ioPortAddr == 0x7): # set data rate
                self.dataRate = data & 0x3
                return
            else:
                self.main.printMsg("FDC_CTRL::outPort: port {0:#06x} not supported. (dataSize byte, data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("FDC_CTRL::outPort: dataSize {0:d} not supported.", dataSize)
    cdef run(self):
        self.reset(True)
        if (self.controllerId == 0):
            if (self.main.fdaFilename): (<FloppyDrive>self.drive[0]).loadDrive(self.main.fdaFilename)
            if (self.main.fdbFilename): (<FloppyDrive>self.drive[1]).loadDrive(self.main.fdbFilename)
    #####

cdef class Floppy:
    def __init__(self, object main):
        self.main = main
        self.controller = (FloppyController(self, 0), FloppyController(self, 1))
    cdef initObjsToNull(self):
        self.cmos = None
        self.pic = None
        self.isaDma = None
    cdef setupDMATransfer(self, FloppyController ctrl):
        if (self.isaDma is not None):
            self.isaDma.setDmaReadFromMem(0, FDC_DMA_CHANNEL, ctrl, (<DmaReadFromMem>ctrl.writeToDrive))
            self.isaDma.setDmaWriteToMem(0, FDC_DMA_CHANNEL, ctrl, (<DmaWriteToMem>ctrl.readFromDrive))
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr >= FDC_FIRST_PORTBASE and ioPortAddr <= FDC_FIRST_PORTBASE+FDC_PORTCOUNT):
                return (<FloppyController>self.controller[0]).inPort(ioPortAddr-FDC_FIRST_PORTBASE, dataSize)
            elif (ioPortAddr >= FDC_SECOND_PORTBASE and ioPortAddr <= FDC_SECOND_PORTBASE+FDC_PORTCOUNT):
                return (<FloppyController>self.controller[1]).inPort(ioPortAddr-FDC_SECOND_PORTBASE, dataSize)
            else:
                self.main.printMsg("inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr >= FDC_FIRST_PORTBASE and ioPortAddr <= FDC_FIRST_PORTBASE+FDC_PORTCOUNT):
                (<FloppyController>self.controller[0]).outPort(ioPortAddr-FDC_FIRST_PORTBASE, data, dataSize)
            elif (ioPortAddr >= FDC_SECOND_PORTBASE and ioPortAddr <= FDC_SECOND_PORTBASE+FDC_PORTCOUNT):
                (<FloppyController>self.controller[1]).outPort(ioPortAddr-FDC_SECOND_PORTBASE, data, dataSize)
            else:
                self.main.printMsg("inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cdef run(self):
        cdef FloppyController controller
        #self.cmos   = self.main.platform.cmos
        #self.isaDma = self.main.platform.isadma
        for controller in self.controller:
            controller.run()
        #self.main.platform.addReadHandlers(FDC_FIRST_READ_PORTS, self)
        #self.main.platform.addReadHandlers(FDC_SECOND_READ_PORTS, self)
        #self.main.platform.addWriteHandlers(FDC_FIRST_WRITE_PORTS, self)
        #self.main.platform.addWriteHandlers(FDC_SECOND_WRITE_PORTS, self)








