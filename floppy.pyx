import os

include "globals.pxi"

ST0_SE = 0x20 # ST0 seek end
ST3_WPDR = 0x40 # ST3 write protected
ST3_RDY = 0x20 # ST3 drive ready
ST3_DSDR = 0x8 # ST3 double sided drive/floppy
DOR_RST = 0x4 # DOR reset
DOR_IRQ = 0x8 # DOR dma && irq enabled
MSR_CB  = 0x10 # MSR command busy
MSR_RQM = 0x80 # MSR ok (or mandatory) to exchange bytes with the FIFO IO port (wiki.osdev.org)
MSR_DIO = 0x40 # MSR FIFO IO port expects an IN opcode (wiki.osdev.org)

cdef class FloppyDrive:
    cdef public object main, fp
    cdef public bytes filename
    cdef public unsigned char driveId, isLoaded
    def __init__(self, object main, unsigned char driveId):
        self.main = main
        self.driveId = driveId
        self.filename = b''
        self.fp = None
        self.isLoaded = False
    def loadDrive(self, bytes filename):
        if (not filename or not os.path.exists(filename)):
            self.main.printMsg("FD{0:d}: loadDrive: filename not found. (filename: {1:s})", self.driveId, filename)
            return
        self.filename = filename
        self.fp = open(filename, "r+b")
        self.isLoaded = True
    def readSectors(self, unsigned long sector, unsigned long count): # count in sectors
        cdef bytes retData
        cdef unsigned long oldPos
        oldPos = self.fp.tell()
        self.fp.seek(sector*512)
        retData = self.fp.read(count*512)
        self.fp.seek(oldPos)
        return retData
    def writeSectors(self, unsigned long sector, bytes data):
        cdef unsigned long oldPos
        if (len(data)%512):
            self.main.exitError("FD{0:d}: writeSectors: datalength invalid. (sector: {1:d}, datalength: {2:d})", self.driveId, sector, len(data))
            return
        oldPos = self.fp.tell()
        self.fp.seek(sector*512)
        retData = self.fp.write(data)
        self.fp.seek(oldPos)
    

cdef class Floppy:
    cdef public object main
    cdef unsigned char msr, dor, st0, st1, st2, st3
    cdef bytes command, result
    cdef dict cmdLengthTable
    cdef tuple readPorts, writePorts
    cdef public tuple floppy
    def __init__(self, object main):
        self.main = main
        self.floppy = (FloppyDrive(self.main, 0), FloppyDrive(self.main, 1), FloppyDrive(self.main, 2), FloppyDrive(self.main, 3))
        self.cmdLengthTable = {0x2: 9, 0x3: 3, 0x4: 2, 0x5: 9, 0x6: 9, 0x7: 2, 0x8: 1, 0xf: 3 }
        self.readPorts = (0x3f0, 0x3f1, 0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f6, 0x3f7)
        self.writePorts = (0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f6, 0x3f7)
        self.reset()
    def reset(self):
        self.msr = 0xc0 # mainStatusRegister
        self.dor = DOR_IRQ | DOR_RST
        self.st0 = 0
        self.st1 = 0
        self.st2 = 0
        self.st3 = 0
        self.command, self.result = b'', b''
    def addToCommand(self, unsigned char command):
        cdef unsigned char cmdLength
        self.result = b''
        self.command += bytes([command])
        cmdLength = self.cmdLengthTable.get(self.command[0]&0x1f)
        if (not cmdLength):
            self.main.exitError("FDC: addToCommand: invalid command")
            return
        if (cmdLength == len(self.command)):
            self.msr |= MSR_CB
            self.handleCommand()
            self.msr &= ~MSR_CB
    def addToResult(self, unsigned char result):
        self.result += bytes([result])
    def setDor(self, unsigned char data):
        cdef unsigned char drive = data & 3
        self.dor = data
        if (not (data & 0x8)):
            self.main.exitError("FDC: outPort_setDor: just DMA is supported yet. (data: {0:#04x})", data)
            return
        if (not (data & DOR_RST)):
            self.reset()
            self.raiseFloppyIrq()
    def setMsr(self, unsigned char data):
        self.msr = data
    def raiseFloppyIrq(self):
        self.main.platform.pic.raiseIrq(FDC_IRQ)
    def handleCommand(self):
        cdef unsigned char cmd = self.command[0]&0x1f
        if (cmd == 0x3): # set drive parameters
            if (self.command[2] & 0x1): # NO DMA
                self.main.exitError("FDC: handleCommand 0x3: just DMA is supported yet.")
                return
        if (cmd == 0x4): # check drive state
            self.st3 = ST3_RDY | ST3_DSDR | self.command[1]&7
            self.addToResult(self.st3)
        elif (cmd in (0x7, 0xf)): # 0x7: calibrate drive ## 0xf: positioning r/w head
            self.raiseFloppyIrq()
            self.st0 = ST0_SE | self.command[1]&7
        elif (cmd == 0x8): # check interrupt state
            self.addToResult(self.st0)
            self.addToResult(0)
        elif (cmd in (0x2,0x5,0x6)): # 0x2: read track/0x5: write sector/0x6: read sector
            drive = self.command[1]&2
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
            realSector = self.ChsToSector(cylinder, head, sector)
            realEndSector = self.ChsToSector(cylinder, head, lastSector)
            if (cmd in (0x2, 0x6)): # read
                data = self.floppy[drive].readSectors(realSector, realEndSector-realSector+1)
                self.main.platform.isadma.handleTransfer(2, data, False)
                self.msr = 0xc0
                self.st0 = ((head&1)<<2) | self.command[1]&7
                self.st3 = ST3_RDY | ST3_DSDR | ((head&1)<<2) | self.command[1]&7
                self.addToResult(self.st0)
                self.addToResult(self.st1)
                self.addToResult(self.st2)
                self.addToResult(cylinder)
                self.addToResult(head)
                self.addToResult(sector)
                self.addToResult(2)
                self.raiseFloppyIrq()
            else:
                self.main.exitError("FDC: handleCommand 0x5: write not implemented yet.")
                return
        self.command = b''
    def ChsToSector(self, unsigned char cylinder, unsigned char head, unsigned char sector):
        return (cylinder*2*18)+(head*18)+(sector-1) # FIXME: 1.44MB floppy
    def inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char result
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x3f2): # read dor
                return self.dor
            elif (ioPortAddr == 0x3f4): # read msr
                if (len(self.result)):
                    self.msr |= MSR_DIO
                else:
                    self.msr &= ~MSR_DIO
                return self.msr
            elif (ioPortAddr == 0x3f5):
                result = self.result[0]
                self.result = self.result[1:]
                return result
            elif (ioPortAddr == 0x3f6):
                self.main.printMsg("inPort: reserved read from port {0:#06x}. (dataSize byte)", ioPortAddr)
            else:
                self.main.printMsg("inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, unsigned short ioPortAddr, unsigned char data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x3f2): # set dor
                drive = data&3
                self.setDor(data)
            elif (ioPortAddr == 0x3f5): # send cmds
                self.addToCommand(data)
            elif (ioPortAddr == 0x3f6):
                self.main.printMsg("outPort: reserved write to port {0:#06x}. (dataSize byte, data {1:#04x})", ioPortAddr, data)
            else:
                self.main.printMsg("outPort: port {0:#06x} not supported. (dataSize byte, data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        if (self.main.fdaFilename):
            self.floppy[0].loadDrive(self.main.fdaFilename)
        if (self.main.fdbFilename):
            self.floppy[1].loadDrive(self.main.fdbFilename)
        self.main.platform.addReadHandlers(self.readPorts, self.inPort)
        self.main.platform.addWriteHandlers(self.writePorts, self.outPort)


