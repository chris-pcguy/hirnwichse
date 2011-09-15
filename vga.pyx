import misc, sys, threading, time, mm, _thread, pygameUI

TEXTMODE_ADDR = 0xb8000

VGA_SEQ_INDEX_ADDR = 0x3c4
VGA_SEQ_DATA_ADDR  = 0x3c5

VGA_SEQ_MAX_INDEX  = 1

VGA_SEQ_DATA_LENGTH = 256
VGA_CRT_DATA_LENGTH = 256
VGA_GDC_DATA_LENGTH = 256
VGA_DAC_DATA_LENGTH = 256
VGA_EXTREG_DATA_LENGTH = 256
VGA_ATTRCTRLREG_DATA_LENGTH = 256



cdef class VGA_REGISTER_RAW:
    cdef object main, vga, csData
    cdef unsigned short csDataSize, index
    def __init__(self, unsigned short csDataSize, object vga, object main):
        self.csDataSize = csDataSize
        self.vga  = vga
        self.main = main
        self.reset()
    def reset(self):
        self.csData  = mm.ConfigSpace(self.csDataSize, self.main)
        self.index = 0
    def getIndex(self):
        return self.index
    def setIndex(self, unsigned short index):
        self.index = index
    def indexAdd(self, unsigned short n):
        self.index += n
    def indexSub(self, unsigned short n):
        self.index -= n
    def getData(self, unsigned char dataSize):
        return self.csData.csReadValue(self.index, dataSize)
    def setData(self, unsigned long long data, unsigned char dataSize):
        self.csData.csWriteValue(self.index, data, dataSize)
    

cdef class CRT(VGA_REGISTER_RAW):
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_CRT_DATA_LENGTH, vga, main)

cdef class DAC(VGA_REGISTER_RAW): # PEL
    cdef unsigned char mask
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_DAC_DATA_LENGTH, vga, main)
        self.mask = 0xff
    def setData(self, int data, unsigned char dataSize):
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        self.indexAdd(1)
    def getMask(self):
        return self.mask
    def setMask(self, int value):
        self.mask = value


cdef class GDC(VGA_REGISTER_RAW):
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_GDC_DATA_LENGTH, vga, main)

cdef class Sequencer(VGA_REGISTER_RAW):
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_SEQ_DATA_LENGTH, vga, main)

cdef class ExtReg(VGA_REGISTER_RAW):
    cdef unsigned char miscOutReg
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_EXTREG_DATA_LENGTH, vga, main)
        self.miscOutReg = 0
    def getMiscOutReg(self):
        return self.miscOutReg
    def setMiscOutReg(self, int value):
        self.miscOutReg = value

cdef class AttrCtrlReg(VGA_REGISTER_RAW):
    cdef unsigned char flipFlop
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_ATTRCTRLREG_DATA_LENGTH, vga, main)
        self.flipFlop = False
    def setIndexData(self, unsigned long long data, unsigned char dataSize):
        if (not self.flipFlop):
            self.setIndex(data)
        else:
            self.setData(data, dataSize)
        self.flipFlop = not self.flipFlop
    


cdef class Vga:
    cdef object main, seq, crt, gdc, dac, extreg, attrctrlreg, pygameUI
    def __init__(self, object main):
        self.main = main
        self.seq = Sequencer(self, self.main)
        self.crt = CRT(self, self.main)
        self.gdc = GDC(self, self.main)
        self.dac = DAC(self, self.main)
        self.extreg = ExtReg(self, self.main)
        self.attrctrlreg = AttrCtrlReg(self, self.main)
        self.pygameUI = pygameUI.pygameUI(self, self.main)
    def inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            if (ioPortAddr == 0x3c6):
                return self.dac.getMask()
            elif (ioPortAddr == 0x3c8):
                return self.dac.getIndex()
            elif (ioPortAddr == 0x3cc):
                return self.extreg.getMiscOutReg()
            elif (ioPortAddr == 0x3c1):
                return self.attrctrlreg.getData(dataSize)
            elif (ioPortAddr == 0x3da):
                return 0
            else:
                self.main.printMsg("inPort: port {0:#04x} not supported. (dataSize byte)", ioPortAddr)
        else:
            if (ioPortAddr == 0x3cc):
                return self.extreg.getMiscOutReg()
            else:
                self.main.exitError("inPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        return 0
    def outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            if (ioPortAddr == 0x400): # Bochs' Panic Port
                sys.stdout.write(chr(data))
                sys.stdout.flush()
            elif (ioPortAddr == 0x401): # Bochs' Panic Port2
                sys.stdout.write(chr(data))
                sys.stdout.flush()
            elif (ioPortAddr in (0x402,0x500)): # Bochs' Info Port
                sys.stdout.write(chr(data))
                sys.stdout.flush()
            elif (ioPortAddr == 0x403): # Bochs' Debug Port
                sys.stdout.write(chr(data))
                sys.stdout.flush()
            elif (ioPortAddr == 0x3c0):
                self.attrctrlreg.setIndexData(data, dataSize)
            elif (ioPortAddr == 0x3c2):
                self.extreg.setMiscOutReg(data)
            elif (ioPortAddr == 0x3c4):
                self.seq.setIndex(data)
            elif (ioPortAddr == 0x3c5):
                self.seq.setData(data, dataSize)
            elif (ioPortAddr == 0x3c6):
                self.dac.setMask(data)
            elif (ioPortAddr == 0x3c8):
                self.dac.setIndex(data)
            elif (ioPortAddr == 0x3c9):
                self.dac.setData(data, dataSize)
            elif (ioPortAddr == 0x3ce):
                self.gdc.setIndex(data)
            elif (ioPortAddr == 0x3cf):
                self.gdc.setData(data, dataSize)
            elif (ioPortAddr == 0x3d4):
                self.crt.setIndex(data)
            elif (ioPortAddr == 0x3d5):
                self.crt.setData(data, dataSize)
            else:
                self.main.printMsg("outPort: port {0:#04x} not supported. (dataSize byte, data {1:#04x})", ioPortAddr, data)
        elif (dataSize == misc.OP_SIZE_WORD):
            if (ioPortAddr == 0x3c4):
                self.seq.setIndex(data)
            elif (ioPortAddr == 0x3ce):
                self.gdc.setIndex(data)
            elif (ioPortAddr == 0x3d4):
                self.crt.setIndex(data)
            elif (ioPortAddr == 0x3d5):
                self.crt.setData(data, dataSize)
            else:
                self.main.printMsg("outPort: port {0:#04x} not supported. (dataSize word, data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        return
    def startThread(self):
        cdef object vidData
        cdef list rectList
        cdef object newRect
        try:
            while (not self.main.quitEmu):
                if (self.main.cpu.cpuHalted):
                    time.sleep(2)
                    continue
                vidData = self.main.mm.mmPhyRead(TEXTMODE_ADDR, 4000) # 4000==80*25*2
                for y in range(25):
                    rectList = []
                    for x in range(80):
                        offset = ((y*80)+x)*2
                        charData = vidData[offset:offset+2]
                        newRect = self.pygameUI.putChar(x, y, chr(charData[0]), charData[1])
                        rectList.append(newRect)
                    if (len(rectList) > 0):
                        self.pygameUI.updateScreen(rectList)
                #time.sleep(0.05)
                time.sleep(0.50)
        #except (SystemExit, KeyboardInterrupt):
        #    _thread.exit()
        except:
            print(sys.exc_info())
            _thread.exit()
        finally:
            _thread.exit()
    def run(self):
        try:
            threading.Thread(target=self.pygameUI.handleThread, name='pygameUI-0').start()
            threading.Thread(target=self.startThread, name='vga-0').start()
            self.main.platform.addReadHandlers((0x3c1,0x3cc,0x3c8,0x3da), self.inPort)
            self.main.platform.addWriteHandlers((0x400, 0x401, 0x402, 0x403, 0x500, 0x3c0, 0x3c2, 0x3c4, 0x3c5, 0x3c6, 0x3c7, 0x3c8, 0x3c9, 0x3ce, 0x3cf, 0x3d4, 0x3d5), self.outPort)
        except:
            print(sys.exc_info())
            _thread.exit()
    


