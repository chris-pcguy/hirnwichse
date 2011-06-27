
import os

SIZE_64KB = 65536
SIZE_128KB = 131072
SIZE_256KB = 262144
SIZE_512KB = 524288
SIZE_1024KB = 1048576
SIZE_2048KB = 2097152
SIZE_4096KB = 4194304
ROM_SIZES = (SIZE_64KB, SIZE_128KB, SIZE_256KB, SIZE_512KB, SIZE_1024KB, SIZE_2048KB, SIZE_4096KB)

class Platform:
    def __init__(self, main):
        self.main = main
    def loadRomToMem(self, romFileName, int mmAddr, int romSize):
        try:    
            if (romSize not in ROM_SIZES):
                self.main.exitError("romSize {0:d} is NOT OK.".format(romSize))
                return False
            romFp = open(romFileName, "rb")
            romData = romFp.read(romSize)
            self.main.mm.mmWrite(mmAddr, romSize, romData)
        finally:
            romFp.close()
    def loadRom(self, romFileName, int mmAddr, isRomOptional):
        cdef int romMemSize = SIZE_64KB
        cdef int romSize = os.stat(romFileName).st_size
        
        if (not isRomOptional):
            if (romSize <= SIZE_64KB):
                romMemSize = SIZE_64KB
                mmAddr = 0xf000
            elif (romSize <= SIZE_128KB):
                romMemSize = SIZE_128KB
                mmAddr = 0xe000
            elif (romSize <= SIZE_256KB):
                romMemSize = SIZE_256KB
                mmAddr = 0xc000
            elif (romSize <= SIZE_512KB):
                romMemSize = SIZE_512KB
                mmAddr = 0x8000
            elif (romSize <= SIZE_1024KB):
                romMemSize = SIZE_1024KB
                mmAddr = 0x0
            else:
                self.main.exitError("romMemSize {0:d} is NOT SUPPORTED!".format(romMemSize))
                return False
        
        return self.loadRomToMem(romFileName, mmAddr, romMemSize)
    def run(self, memSize):
        self.main.mm.mmAddArea(0, memSize)
        self.loadRom(os.path.join(self.main.romPath, "bios.bin"), 0xf0000, isRomOptional=False)
        self.loadRom(os.path.join(self.main.romPath, "vgabios.bin"), 0xc0000, isRomOptional=True)
        



