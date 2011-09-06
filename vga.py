import misc, sys, threading, time, mm #, cursesUI

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



class VGA_REGISTER_RAW:
    def __init__(self, csDataSize, vga, main):
        self.csDataSize = csDataSize
        self.vga  = vga
        self.main = main
        self.reset()
    def reset(self):
        self.csData  = mm.ConfigSpace(self.csDataSize, self.main)
        self.index = 0
    def getIndex(self):
        return self.index
    def setIndex(self, index):
        self.index = index
    def indexAdd(self, n):
        self.index += n
    def indexSub(self, n):
        self.index -= n
    def getData(self, dataSize):
        return self.csData.csReadValue(self.index, dataSize)
    def setData(self, data, dataSize):
        self.csData.csWriteValue(self.index, data, dataSize)
    

class CRT(VGA_REGISTER_RAW):
    def __init__(self, vga, main):
        VGA_REGISTER_RAW.__init__(self, VGA_CRT_DATA_LENGTH, vga, main)

class DAC(VGA_REGISTER_RAW):
    def __init__(self, vga, main):
        VGA_REGISTER_RAW.__init__(self, VGA_DAC_DATA_LENGTH, vga, main)
    def setData(self, data, dataSize):
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        self.indexAdd(1)

class GDC(VGA_REGISTER_RAW):
    def __init__(self, vga, main):
        VGA_REGISTER_RAW.__init__(self, VGA_GDC_DATA_LENGTH, vga, main)

class Sequencer(VGA_REGISTER_RAW):
    def __init__(self, vga, main):
        VGA_REGISTER_RAW.__init__(self, VGA_SEQ_DATA_LENGTH, vga, main)

class ExtReg(VGA_REGISTER_RAW):
    def __init__(self, vga, main):
        VGA_REGISTER_RAW.__init__(self, VGA_EXTREG_DATA_LENGTH, vga, main)
        self.miscOutReg = 0
    def getMiscOutReg(self):
        return self.miscOutReg
    def setMiscOutReg(self, value):
        self.miscOutReg = value

class AttrCtrlReg(VGA_REGISTER_RAW):
    def __init__(self, vga, main):
        VGA_REGISTER_RAW.__init__(self, VGA_ATTRCTRLREG_DATA_LENGTH, vga, main)
        self.flipFlop = False
    def setIndexData(self, data, dataSize):
        if (not self.flipFlop):
            self.setIndex(data)
        else:
            self.setData(data, dataSize)
        self.flipFlop = not self.flipFlop
    


class Vga:
    def __init__(self, main):
        self.main = main
        self.seq = Sequencer(self, self.main)
        self.crt = CRT(self, self.main)
        self.gdc = GDC(self, self.main)
        self.dac = DAC(self, self.main)
        self.extreg = ExtReg(self, self.main)
        self.attrctrlreg = AttrCtrlReg(self, self.main)
        #self.cursesUI = cursesUI.cursesUI(self.main)
    def inPort(self, ioPortAddr, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr == 0x3c8):
                return self.dac.getIndex()
            elif (ioPortAddr == 0x3c2):
                return self.extreg.getMiscOutReg()
            elif (ioPortAddr == 0x3c1):
                return self.attrctrlreg.getData(dataSize)
            elif (ioPortAddr == 0x3da):
                return 0
            else:
                self.main.printMsg("inPort: port {0:#04x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("inPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        return 0
    def outPort(self, ioPortAddr, data, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr == 0x400): # Bochs' Panic Port
                #print('Panic port: byte=={0:#04x}'.format(data))
                sys.stdout.write(chr(data))
                sys.stdout.flush()
            elif (ioPortAddr == 0x401): # Bochs' Panic Port2
                #print('Panic port2: byte=={0:#04x}'.format(data))
                sys.stdout.write(chr(data))
                sys.stdout.flush()
            elif (ioPortAddr in (0x402,0x500)): # Bochs' Info Port
                #print('Info port: byte=={0:#04x}'.format(data))
                sys.stdout.write(chr(data))
                sys.stdout.flush()
            elif (ioPortAddr == 0x403): # Bochs' Debug Port
                #print('Debug port: byte=={0:#04x}'.format(data))
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
        elif (dataSize == misc.OP_SIZE_16BIT):
            if (ioPortAddr == 0x3d4):
                self.crt.setIndex(data)
            elif (ioPortAddr == 0x3d5):
                self.crt.setData(data, dataSize)
            else:
                self.main.printMsg("outPort: port {0:#04x} not supported. (dataSize word, data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        return
    def startThread(self):
        try:
            while (not self.main.quitEmu):
                vidData = self.main.mm.mmPhyRead(TEXTMODE_ADDR, 4000) # 4000==80*25*2
                for y in range(25):
                    for x in range(80):
                        offset = (y*80)+x
                        charData = vidData[offset:offset+2]
                        #self.cursesUI.putChar(y, x, charData[0])
                time.sleep(0.05)
        except KeyboardInterrupt:
            sys.exit(1)
        finally:
            sys.exit(0)
    def run(self):
        #self.cursesUI.run()
        self.main.platform.addReadHandlers((0x3c1,0x3c2,0x3c8,0x3da), self.inPort)
        self.main.platform.addWriteHandlers((0x400, 0x401, 0x402, 0x403, 0x500, 0x3c0, 0x3c2, 0x3c4, 0x3c5, 0x3c6, 0x3c7, 0x3c8, 0x3c9, 0x3ce, 0x3cf, 0x3d4, 0x3d5), self.outPort)
        #threading.Thread(target=self.startThread, name='vga-0').start()


