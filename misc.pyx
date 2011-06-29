import struct

DATA_ORDER_LITTLE_ENDIAN = 10
DATA_ORDER_BIG_ENDIAN = 11


class Misc:
    def __init__(self, main):
        self.main = main
    def getBitMask(self, bits):
        return (1<<bits)-1
    def binToNum(self, binStr, int binSize, int signedValue=False): # uses little endian; binSize in bytes
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
        try:
            return struct.unpack(binFormat, binStr)[0]
        except struct.error:
            return None
    def numToBin(self, long num, int binSize, int signedValue=False): # uses little endian; binSize in bytes
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
        try:
            return struct.pack(binFormat, num)
        except struct.error:
            return None
    def binToNumNoStruct(self, binStr, int dataOrder): # usually for very long strings.
        retNum = 0
        cdef long i = len(binStr)
        if (dataOrder == DATA_ORDER_LITTLE_ENDIAN):
            while (i>0):
                i -= 1
                retNum <<= 8
                retNum |= binStr[i]
            return retNum
        elif (dataOrder == DATA_ORDER_BIG_ENDIAN):
            self.main.exitError("numToBinNoStruct: BigEndian NOT SUPPORTED yet.")
        else:
            self.main.exitError("numToBinNoStruct: dataOrder is unknown. (dataOrder: {0:d})", dataOrder)
        return None
    def numToBinNoStruct(self, num, long dataSize, int dataOrder): # usually for very large integers.; dataSize in bytes
        if (dataSize == 0):
            self.main.exitError("numToBinNoStruct: dataSize == 0.")
            return
        if (num == 0):
            return b'\x00'*dataSize
        retBinStr = bytearray()
        if (dataOrder == DATA_ORDER_LITTLE_ENDIAN):
            while (num > 0):
                retBinStr += bytes([num&0xff])
                num >>= 8
            return retBinStr
        elif (dataOrder == DATA_ORDER_BIG_ENDIAN):
            self.main.exitError("numToBinNoStruct: BigEndian NOT SUPPORTED yet.")
        else:
            self.main.exitError("numToBinNoStruct: dataOrder is unknown. (dataOrder: {0:d})", dataOrder)
        return None


