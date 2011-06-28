import struct

class Misc:
    def __init__(self, main):
        self.main = main
    def getBitMask(self, bits):
        return (1<<bits)-1
    def binToNum(self, binStr, int binSize, int signedValue=False): # uses little endian
        binFormat = ""
        if (binSize == 8):
            binFormat = ((signedValue and "<q") or "<Q")
        elif (binSize == 4):
            binFormat = ((signedValue and "<i") or "<I")
        elif (binSize == 2):
            binFormat = ((signedValue and "<h") or "<H")
        elif (binSize == 1):
            binFormat = ((signedValue and "<b") or "<B")
        else:
            self.main.exitError("binSize NOT OK. ({0:d})", binSize)
        return struct.unpack(binFormat, binStr)[0]
    def numToBin(self, long num, int binSize, int signedValue=False): # uses little endian
        binFormat = ""
        if (binSize == 8):
            binFormat = ((signedValue and "<q") or "<Q")
        elif (binSize == 4):
            binFormat = ((signedValue and "<i") or "<I")
        elif (binSize == 2):
            binFormat = ((signedValue and "<h") or "<H")
        elif (binSize == 1):
            binFormat = ((signedValue and "<b") or "<B")
        else:
            self.main.exitError("binSize NOT OK. ({0:d})", binSize)
        return struct.pack(binFormat, num)



