
from os import access, F_OK, R_OK, W_OK
from os.path import getsize

# This file contains (much) code from the Bochs Emulator (c) by it's developers


include "globals.pxi"

DEF FDC_FIRST_PORTBASE  = 0x3f0
DEF FDC_SECOND_PORTBASE = 0x370
DEF FDC_PORTCOUNT       = 7
DEF FDC_DMA_CHANNEL     = 2
DEF FDC_IRQ = 6 # floppy disk controller's IRQnum

DEF FDC_ST0_NR = 0x8 # ST0 drive not ready
DEF FDC_ST0_UC = 0x10 # ST0 unit check, set on error
DEF FDC_ST0_SE = 0x20 # ST0 seek end
DEF FDC_ST1_NID = 0x1 # ST1 no address mark
DEF FDC_ST1_NW = 0x2 # ST1 write protected
DEF FDC_ST1_NDAT = 0x4 # ST1 no data
DEF FDC_ST1_TO = 0x10 # ST1 time-out
DEF FDC_ST1_DE = 0x20 # ST1 data error
DEF FDC_ST1_EN = 0x80 # ST1 end of cylinder
DEF FDC_ST3_DSDR = 0x8 # ST3 double sided drive/floppy
DEF FDC_ST3_TRKO = 0x10 # ST3 track 0 seeked
DEF FDC_ST3_RDY = 0x20 # ST3 drive ready
DEF FDC_ST3_WPDR = 0x40 # ST3 write protected
DEF FDC_DOR_NORESET = 0x4 # DOR reset
DEF FDC_DOR_DMA = 0x8 # DOR dma && irq enabled
DEF FDC_MSR_BUSY = 0x10 # MSR command busy
DEF FDC_MSR_NODMA = 0x20 # MSR just use PIO. (NO DMA!)
DEF FDC_MSR_DIO = 0x40 # MSR FIFO IO port expects an IN opcode (wiki.osdev.org)
DEF FDC_MSR_RQM = 0x80 # MSR ok (or mandatory) to exchange bytes with the FIFO IO port (wiki.osdev.org)
DEF FDC_CMD_SK = 0x20 # command is using skip-mode
DEF FDC_CMD_MF = 0x40 # command is using mfm
DEF FDC_CMD_MT = 0x80 # command is using multi-track
DEF FDC_SECTOR_SIZE = 512

DEF FDC_CMDLENGTH_TABLE = (None, None, None, 3, 2, 9, 9, 2, 1, None, 2, None, None, None, None, 3)


cdef class FloppyMedia:
    def __init__(self, FloppyDrive floppyDrive):
        self.floppyDrive = floppyDrive
        self.mediaType = FLOPPY_DISK_TYPE_NONE
        self.tracks = self.heads = self.sectorsPerTrack = self.sectors = 0
    cdef void setDataForMedia(self, unsigned char mediaType):
        self.mediaType = mediaType
        if (mediaType == FLOPPY_DISK_TYPE_NONE):
            self.tracks = self.heads = self.sectorsPerTrack = self.sectors = 0
        elif (mediaType in (FLOPPY_DISK_TYPE_360K, FLOPPY_DISK_TYPE_1_2M, FLOPPY_DISK_TYPE_720K, \
           FLOPPY_DISK_TYPE_1_44M, FLOPPY_DISK_TYPE_2_88M)):
            self.heads = 2
            if (mediaType in (FLOPPY_DISK_TYPE_160K, FLOPPY_DISK_TYPE_180K, FLOPPY_DISK_TYPE_320K, FLOPPY_DISK_TYPE_360K)):
                self.tracks = 40
                if (mediaType in (FLOPPY_DISK_TYPE_180K, FLOPPY_DISK_TYPE_360K)):
                    self.sectorsPerTrack = 9
                else:
                    self.sectorsPerTrack = 8
                if (mediaType == FLOPPY_DISK_TYPE_160K):
                    self.sectors = 320
                elif (mediaType == FLOPPY_DISK_TYPE_180K):
                    self.sectors = 360
                elif (mediaType == FLOPPY_DISK_TYPE_320K):
                    self.sectors = 640
                elif (mediaType == FLOPPY_DISK_TYPE_360K):
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
    cdef unsigned int ChsToSector(self, unsigned char cylinder, unsigned char head, unsigned char sector):
        return (cylinder*self.media.heads*self.media.sectorsPerTrack)+(head*self.media.sectorsPerTrack)+(sector-1)
    cdef unsigned char getDiskType(self, unsigned int size):
        cdef unsigned char diskType = FLOPPY_DISK_TYPE_NONE
        cdef unsigned char diskTypeOverride = FLOPPY_DISK_TYPE_NONE
        if (self.driveId == 0):
            diskTypeOverride = self.main.fdaType
        elif (self.driveId == 1):
            diskTypeOverride = self.main.fdbType
        if (diskTypeOverride != FLOPPY_DISK_TYPE_NONE):
            diskType = diskTypeOverride
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
            self.main.notice("FloppyDrive::getDiskType: can't assign filesize {0:d} to a type, mark disk as unrecognized", size)
        self.main.notice("FloppyDrive::getDiskType: floppy has disktype {0:d}.", diskType)
        return diskType
    cdef void loadDrive(self, bytes filename):
        cdef unsigned char cmosDiskType, driveType
        if (not filename or not access(filename, F_OK | R_OK)):
            self.main.notice("FD{0:d}: loadDrive: file isn't found/accessable. (filename: {1:s})", self.driveId, filename)
            return
        self.filename = filename
        driveType = self.getDiskType(getsize(self.filename))
        self.media.setDataForMedia(driveType)
        if (driveType == FLOPPY_DISK_TYPE_NONE):
            self.main.notice("FloppyDrive::loadDrive: driveType is DISK_TYPE_NONE")
            return
        elif (access(filename, F_OK | R_OK | W_OK)):
            self.fp = open(filename, "r+b")
            self.isLoaded = True
            self.isWriteProtected = False
        elif (access(filename, F_OK | R_OK)):
            self.fp = open(filename, "rb")
            self.isLoaded = True
            self.isWriteProtected = True
        else:
            self.main.notice("FD{0:d}: loadDrive: file isn't found/accessable. (filename: {1:s}, access-cmd)", self.driveId, filename)
            return
        if (self.driveId in (0, 1)):
            cmosDiskType = (<Cmos>self.main.platform.cmos).readValue(CMOS_FLOPPY_DRIVE_TYPE, OP_SIZE_BYTE)
            if (self.driveId == 0):
                cmosDiskType &= 0x0f
                cmosDiskType |= (driveType&0xf)<<4
            elif (self.driveId == 1):
                cmosDiskType &= 0xf0
                cmosDiskType |= driveType&0xf
            (<Cmos>self.main.platform.cmos).writeValue(CMOS_FLOPPY_DRIVE_TYPE, cmosDiskType, OP_SIZE_BYTE)
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
        return self.readBytes(sector<<9, count<<9)
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
        self.writeBytes(sector<<9, count<<9, data)


cdef class FloppyController:
    def __init__(self, Floppy fdc, unsigned char controllerId):
        self.fdc = fdc
        self.main = self.fdc.main
        self.controllerId = controllerId
        self.fdcBufferIndex = 0 # TODO: maybe move this line...
        self.command = self.result = self.fdcBuffer = b"" # and this too, to reset?
        self.drive = (FloppyDrive(self, 0), FloppyDrive(self, 1), FloppyDrive(self, 2), FloppyDrive(self, 3))
    cdef void reset(self, unsigned char hwReset):
        cdef unsigned char i
        if (self.msr & FDC_MSR_NODMA):
            self.main.exitError("FDC::reset: PIO mode isn't fully supported yet.")
            return
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
        (<IsaDma>self.main.platform.isadma).setDRQ(FDC_DMA_CHANNEL, False)
        self.handleIdle()
    cdef bytes floppyXfer(self, unsigned char drive, unsigned int sector, unsigned int count, bytes data, unsigned char toFloppy):
        if (toFloppy):
            (<FloppyDrive>self.drive[drive]).writeSectors(sector, count, data)
            return
        return (<FloppyDrive>self.drive[drive]).readSectors(sector, count)
    cdef void addCommand(self, unsigned char command):
        cdef unsigned char cmdLength, cmd
        if (self.msr & FDC_MSR_NODMA):
            self.main.exitError("FDC::addCommand: PIO mode isn't fully supported yet.")
            return
        cmdLength = 0
        if (len(self.command) == 0):
            self.msr &= ~FDC_MSR_DIO
            self.msr |= (FDC_MSR_RQM | FDC_MSR_BUSY)
        self.addToCommand(command)
        cmd = self.command[0]&0x1f
        try:
            cmdLength = FDC_CMDLENGTH_TABLE[cmd]
        except IndexError:
            cmdLength = None
        if (not cmdLength):
            self.main.exitError("FDC: addCommand: invalid command: {0:#04x}", cmd)
            return
        if (len(self.command) == cmdLength):
            self.handleCommand()
            return
        elif (len(self.command) > cmdLength):
            self.main.exitError("FDC: addCommand: command {0:#04x} too int (current length: {1:d}, correct length: {2:d}).", cmd, len(self.command), cmdLength)
            return
    cdef inline void addToCommand(self, unsigned char command):
        self.command += bytes([command])
    cdef inline void addToResult(self, unsigned char result):
        self.result += bytes([result])
    cdef inline void clearCommand(self):
        self.command = b""
    cdef inline void clearResult(self):
        self.result = b""
    cdef void setDor(self, unsigned char data):
        cdef unsigned char normalOperation, prevNormalOperation
        if (self.msr & FDC_MSR_NODMA):
            self.main.exitError("FDC::setDor: PIO mode isn't fully supported yet.")
            return
        normalOperation = data & 0x4
        prevNormalOperation = self.DOR & 0x4
        self.DOR = data
        #if (not prevNormalOperation and normalOperation): # reset -> normal
        #    pass
        #el
        if (prevNormalOperation and not normalOperation): # normal -> reset
            self.msr &= FDC_MSR_NODMA
            self.doCmdReset()
    cdef inline void setMsr(self, unsigned char data):
        self.msr = data
    cdef void doCmdReset(self):
        self.reset(False)
        self.clearCommand()
        self.st0 = 0xc0
        self.raiseFloppyIrq()
        self.resetSensei = 4
    cdef void resetChangeline(self):
        cdef unsigned char drive
        if (self.msr & FDC_MSR_NODMA):
            self.main.exitError("FDC::resetChangeline: PIO mode isn't fully supported yet.")
            return
        drive = self.DOR & 0x3
        if ((<FloppyDrive>self.drive[drive]).isLoaded):
            (<FloppyDrive>self.drive[drive]).DIR &= ~0x80
    cdef void incrementSector(self):
        cdef unsigned char drive
        if (self.msr & FDC_MSR_NODMA):
            self.main.exitError("FDC::incrementSector: PIO mode isn't fully supported yet.")
            return
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
    cdef unsigned char getTC(self):
        cdef unsigned char drive, TC
        if (self.msr & FDC_MSR_NODMA):
            self.main.exitError("FDC::getTC: PIO mode isn't fully supported yet.")
            return False
        self.fdc.setupDMATransfer(self)
        TC = (<IsaDma>self.main.platform.isadma).getTC()
        return TC
    cdef void handleResult(self):
        cdef unsigned char drive, cmd
        if (self.msr & FDC_MSR_NODMA):
            self.main.exitError("FDC::handleResult: PIO mode isn't fully supported yet.")
            return
        drive = self.DOR & 0x3
        cmd = self.command[0]&0x1f
        self.clearResult()
        self.msr |= (FDC_MSR_RQM | FDC_MSR_DIO | FDC_MSR_BUSY)

        if ((self.st0 & 0xc0) == 0x80):
            self.addToResult(self.st0)
            return

        if (len(self.command) > 0):
            if (cmd == 0x4):
                self.addToResult(self.st3)
            elif (cmd == 0x8):
                self.addToResult(self.st0)
                self.addToResult((<FloppyDrive>self.drive[drive]).cylinder)
            elif (cmd in (0x5, 0x6, 0xa, 0xd)):
                self.addToResult(self.st0)
                self.addToResult(self.st1)
                self.addToResult(self.st2)
                self.addToResult((<FloppyDrive>self.drive[drive]).cylinder)
                self.addToResult((<FloppyDrive>self.drive[drive]).head)
                self.addToResult((<FloppyDrive>self.drive[drive]).sector)
                self.addToResult(2)
                self.raiseFloppyIrq()
            else:
                self.main.exitError("FDC_CTRL::handleResult: unknown command: {0:#04x}", cmd)
        else:
            self.main.exitError("FDC_CTRL::handleResult: self.command is empty.")
    cdef void handleIdle(self):
        self.msr &= (FDC_MSR_NODMA | 0xf)
        self.msr |= FDC_MSR_RQM
        self.clearCommand()
        self.fdcBufferIndex = 0
    cdef void handleCommand(self):
        cdef unsigned char drive, cmd, motorOn, head, cylinder, sector, eot, sectorSize
        cdef unsigned int logicalSector
        if (self.msr & FDC_MSR_NODMA):
            self.main.exitError("FDC::handleCommand: PIO mode isn't fully supported yet.")
            return
        cmd = self.command[0]
        self.multiTrack = (cmd & FDC_CMD_MT) != 0
        cmd &= 0x1f
        self.msr |= FDC_MSR_RQM | FDC_MSR_DIO | FDC_MSR_BUSY
        self.fdc.setupDMATransfer(self)
        if (cmd == 0x3): # set drive parameters
            if (self.command[2] & 0x1):
                self.main.exitError("FDC::handleCommand 0x3: PIO mode isn't fully supported yet.")
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
        elif (cmd in (0x5, 0x6)):
            if (not (self.DOR & 0x8)):
                self.main.exitError("FDC: read/write command with DMA and INT disabled.")
                return
            drive = self.command[1] & 0x3
            self.DOR &= 0xfc
            self.DOR |= drive
            motorOn = (self.DOR >> (drive+4)) & 0x1
            if (not motorOn): # TODO: what to do here?
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
                self.main.notice("FDC ERROR: head number in command[1] doesn't match head field.")
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
                self.main.notice("FDC: attempt to read/write sector {0:d} past last sector {1:d}.", sector, (<FloppyDrive>self.drive[drive]).media.sectorsPerTrack)
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
            
            if (not eot):
                eot = (<FloppyDrive>self.drive[drive]).media.sectorsPerTrack

            (<FloppyDrive>self.drive[drive]).cylinder = cylinder
            (<FloppyDrive>self.drive[drive]).head = head
            (<FloppyDrive>self.drive[drive]).sector = sector
            (<FloppyDrive>self.drive[drive]).eot = eot

            if (self.msr & FDC_MSR_NODMA):
                self.main.exitError("FDC_CTRL::handleCommand: PIO mode isn't supported!")
                return
            if ((cmd & 0x1f) == 0x5): # write
                (<IsaDma>self.main.platform.isadma).setDRQ(FDC_DMA_CHANNEL, True)
            elif ((cmd & 0x1f) == 0x6): # read
                self.fdcBuffer = self.floppyXfer(drive, logicalSector, 1, b"", False)
                (<IsaDma>self.main.platform.isadma).setDRQ(FDC_DMA_CHANNEL, True)
            else:
                self.main.exitError("FDC: handleCommand: unknown r/w cmd {0:#04x}.", cmd)
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
            self.st0 = FDC_ST0_SE | drive
            if (cmd == 0x7):
                motorOn = (self.DOR >> (drive+4)) & 0x1
                if ((<FloppyDrive>self.drive[drive]).media.mediaType == FLOPPY_DISK_TYPE_NONE or not motorOn):
                    self.st0 |= 0x50
            else:
                self.st0 |= ((<FloppyDrive>self.drive[drive]).head << 2)
            self.handleIdle()
            self.raiseFloppyIrq()
            return
        elif (cmd == 0x8): # check interrupt state
            if (self.resetSensei > 0):
                drive = 4 - self.resetSensei
                self.st0 &= 0xf8
                self.st0 |= ((<FloppyDrive>self.drive[drive]).head << 2) | drive
                self.resetSensei -= 1
            elif (not self.pendingIrq):
                self.st0 = 0x80
            self.handleResult()
            return
        elif (cmd == 0xa): # read id
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
        else:
            self.main.notice("FDC: handleCommand: unknown command {0:#04x}.", cmd)
            self.clearCommand()
            self.st0 = 0x80
            self.handleResult()
    cdef void readFromMem(self, unsigned char data):
        cdef unsigned char drive
        cdef unsigned int logicalSector
        if (self.msr & FDC_MSR_NODMA):
            self.main.exitError("FDC_CTRL::readFromMem: PIO mode isn't supported!")
            return
        drive = self.DOR & 0x3
        if (self.fdcBufferIndex == 0):
            self.fdcBuffer = bytes([data])
        else:
            self.fdcBuffer += bytes([data])
        self.fdcBufferIndex += 1
        self.TC = self.getTC()
        if (self.fdcBufferIndex >= 512 or self.TC):
            if ((<FloppyDrive>self.drive[drive]).isWriteProtected):
                self.st0 = 0x40 | ((<FloppyDrive>self.drive[drive]).head << 2) | drive
                self.st1 = 0x27
                self.st2 = 0x31
                self.handleResult()
                return
            logicalSector = (<FloppyDrive>self.drive[drive]).ChsToSector((<FloppyDrive>self.drive[drive]).\
              cylinder, (<FloppyDrive>self.drive[drive]).head, (<FloppyDrive>self.drive[drive]).sector)
            self.floppyXfer(drive, logicalSector, 1, self.fdcBuffer, True)
            self.incrementSector()
            self.fdcBufferIndex = 0
            if (self.TC):
                self.st0 = ((<FloppyDrive>self.drive[drive]).head << 2) | drive
                self.st1 = self.st2 = 0
                (<IsaDma>self.main.platform.isadma).setDRQ(FDC_DMA_CHANNEL, False)
                self.handleResult()
            else:
                (<IsaDma>self.main.platform.isadma).setDRQ(FDC_DMA_CHANNEL, True)
    cdef unsigned char writeToMem(self):
        cdef unsigned char drive, data
        cdef unsigned int logicalSector
        if (self.msr & FDC_MSR_NODMA):
            self.main.exitError("FDC_CTRL::writeToMem: PIO mode isn't supported!")
            return 0
        drive = self.DOR & 0x3
        data = 0
        if (self.fdcBufferIndex < len(self.fdcBuffer)):
            data = self.fdcBuffer[self.fdcBufferIndex]
        self.fdcBufferIndex += 1
        self.TC = self.getTC()
        if (self.fdcBufferIndex >= 512 or self.TC):
            if (self.fdcBufferIndex >= 512):
                self.incrementSector()
                self.fdcBufferIndex = 0
            if (self.TC):
                self.st0 = ((<FloppyDrive>self.drive[drive]).head << 2) | drive
                self.st1 = self.st2 = 0
                (<IsaDma>self.main.platform.isadma).setDRQ(FDC_DMA_CHANNEL, False)
                self.handleResult()
            else:
                logicalSector = (<FloppyDrive>self.drive[drive]).ChsToSector((<FloppyDrive>self.drive[drive]).cylinder, (<FloppyDrive>self.drive[drive]).head, (<FloppyDrive>self.drive[drive]).sector)
                self.fdcBuffer = self.floppyXfer(drive, logicalSector, 1, b"", False)
                (<IsaDma>self.main.platform.isadma).setDRQ(FDC_DMA_CHANNEL, True)
        return data
    cdef void raiseFloppyIrq(self):
        (<Pic>self.main.platform.pic).raiseIrq(FDC_IRQ)
        self.pendingIrq = True
        self.resetSensei = 0
    cdef void lowerFloppyIrq(self):
        if (self.pendingIrq):
            (<Pic>self.main.platform.pic).lowerIrq(FDC_IRQ)
            self.pendingIrq = False
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char drive, value
        if (self.msr & FDC_MSR_NODMA):
            self.main.exitError("FDC_CTRL::inPort: PIO mode isn't supported!")
            return BITMASK_BYTE
        elif (dataSize == OP_SIZE_BYTE):
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
                    self.main.notice("FDC_CTRL::inPort: controller not ready for reading")
                    return BITMASK_BYTE
                drive = self.result[0]
                if (len(self.result) > 1):
                    self.result = self.result[1:]
                else:
                    self.clearResult()
                self.msr &= 0xf0
                self.lowerFloppyIrq()
                if (not len(self.result)):
                    self.handleIdle()
                return drive # previous result[0]
            elif (ioPortAddr == 0x6):
                return (<Ata>self.main.platform.ata).inPort(ioPortAddr, dataSize)
            elif (ioPortAddr == 0x7):
                value = (<Ata>self.main.platform.ata).inPort(ioPortAddr, dataSize)&0x7f
                drive = self.DOR & 0x3
                if (self.DOR & (1<<(drive+4))):
                    value |= ((<FloppyDrive>self.drive[drive]).DIR & 0x80)
                return value
            else:
                self.main.exitError("FDC_CTRL::inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("FDC_CTRL::inPort: dataSize {0:d} not supported.", dataSize)
        return BITMASK_BYTE
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (self.msr & FDC_MSR_NODMA):
            self.main.exitError("FDC_CTRL::outPort: PIO mode isn't supported!")
            return
        elif (dataSize == OP_SIZE_BYTE):
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
                self.addCommand(data)
                return
            elif (ioPortAddr == 0x6):
                ##self.main.debug("FDC_CTRL::outPort: hdc-shared port {0:#06x} not supported. (dataSize byte, data {1:#04x})", ioPortAddr, data)
                return # TODO: 0x3f6/0x376 should be shared with hard disk controller.
            elif (ioPortAddr == 0x7): # set data rate
                self.dataRate = data & 0x3
                return
            else:
                self.main.exitError("FDC_CTRL::outPort: port {0:#06x} not supported. (dataSize byte, data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("FDC_CTRL::outPort: dataSize {0:d} not supported., (port: {1:#06x})", dataSize, ioPortAddr)
    cdef void run(self):
        cdef unsigned char fdaLoaded, fdbLoaded, cmosVal
        self.reset(True)
        if (self.controllerId == 0):
            if (self.main.fdaFilename): (<FloppyDrive>self.drive[0]).loadDrive(self.main.fdaFilename)
            if (self.main.fdbFilename): (<FloppyDrive>self.drive[1]).loadDrive(self.main.fdbFilename)
            fdaLoaded = (<FloppyDrive>self.drive[0]).isLoaded
            fdbLoaded = (<FloppyDrive>self.drive[1]).isLoaded
            cmosVal = (<Cmos>self.main.platform.cmos).readValue(CMOS_EQUIPMENT_BYTE, OP_SIZE_BYTE)
            if (fdaLoaded or fdbLoaded):
                cmosVal |= 0x1
                if (fdaLoaded and fdbLoaded):
                    cmosVal |= 0x40
            (<Cmos>self.main.platform.cmos).writeValue(CMOS_EQUIPMENT_BYTE, cmosVal, OP_SIZE_BYTE)
            (<Cmos>self.main.platform.cmos).setEquipmentDefaultValue(cmosVal)

    #####

cdef class Floppy:
    def __init__(self, object main):
        self.main = main
        self.controller = (FloppyController(self, 0), FloppyController(self, 1))
    cdef void setupDMATransfer(self, FloppyController classInstance):
        (<IsaDma>self.main.platform.isadma).setDmaMemActions(0, FDC_DMA_CHANNEL, classInstance, \
          <ReadFromMem>classInstance.readFromMem, <WriteToMem>classInstance.writeToMem)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr >= FDC_FIRST_PORTBASE and ioPortAddr <= FDC_FIRST_PORTBASE+FDC_PORTCOUNT):
                return (<FloppyController>self.controller[0]).inPort(ioPortAddr-FDC_FIRST_PORTBASE, dataSize)
            elif (ioPortAddr >= FDC_SECOND_PORTBASE and ioPortAddr <= FDC_SECOND_PORTBASE+FDC_PORTCOUNT):
                return (<FloppyController>self.controller[1]).inPort(ioPortAddr-FDC_SECOND_PORTBASE, dataSize)
            else:
                self.main.exitError("inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr >= FDC_FIRST_PORTBASE and ioPortAddr <= FDC_FIRST_PORTBASE+FDC_PORTCOUNT):
                (<FloppyController>self.controller[0]).outPort(ioPortAddr-FDC_FIRST_PORTBASE, data, dataSize)
            elif (ioPortAddr >= FDC_SECOND_PORTBASE and ioPortAddr <= FDC_SECOND_PORTBASE+FDC_PORTCOUNT):
                (<FloppyController>self.controller[1]).outPort(ioPortAddr-FDC_SECOND_PORTBASE, data, dataSize)
            else:
                self.main.exitError("outPort: port {0:#06x} not supported. (data: {1:#04x}, dataSize byte)", ioPortAddr, data)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cdef void run(self):
        cdef FloppyController controller
        for controller in self.controller:
            controller.run()



