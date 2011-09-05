import misc, sys, threading, time #, cursesUI

TEXTMODE_ADDR = 0xb8000

class Vga:
    def __init__(self, main):
        self.main = main
        #self.cursesUI = cursesUI.cursesUI(self.main)
    def inPort(self, ioPortAddr, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            pass
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
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
            elif (ioPortAddr == 0x402): # Bochs' Info Port
                #print('Info port: byte=={0:#04x}'.format(data))
                sys.stdout.write(chr(data))
                sys.stdout.flush()
            elif (ioPortAddr == 0x403): # Bochs' Debug Port
                #print('Debug port: byte=={0:#04x}'.format(data))
                sys.stdout.write(chr(data))
                sys.stdout.flush()
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
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
        self.main.platform.addReadHandlers((0x400, 0x401, 0x402, 0x403), self.inPort)
        self.main.platform.addWriteHandlers((0x400, 0x401, 0x402, 0x403), self.outPort)
        #threading.Thread(target=self.startThread, name='vga-0').start()


