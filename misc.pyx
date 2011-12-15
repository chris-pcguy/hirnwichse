import threading

include "globals.pxi"


class ChemuException(Exception):
    pass


cdef class Misc:
    def __init__(self, object main):
        self.main = main
    cdef unsigned long long getBitMask7F(self, unsigned char maskSize):
        if (maskSize == OP_SIZE_BYTE):
            return 0x7f
        elif (maskSize == OP_SIZE_WORD):
            return 0x7fff
        elif (maskSize == OP_SIZE_DWORD):
            return 0x7fffffff
        elif (maskSize == OP_SIZE_QWORD):
            return 0x7fffffffffffffff
        else:
            self.main.exitError("Misc::getBitMask: maskSize {0:d} not in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD, OP_SIZE_QWORD)", maskSize)
        return 0
    cdef unsigned long long getBitMask80(self, unsigned char maskSize):
        return self.getBitMask7F(maskSize)+1
    cdef unsigned long long getBitMaskFF(self, unsigned char maskSize):
        if (maskSize == OP_SIZE_BYTE):
            return 0xffUL
        elif (maskSize == OP_SIZE_WORD):
            return 0xffffUL
        elif (maskSize == OP_SIZE_DWORD):
            return 0xffffffffUL
        elif (maskSize == OP_SIZE_QWORD):
            return 0xffffffffffffffffULL
        else:
            self.main.exitError("Misc::getBitMask: maskSize {0:d} not in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD, OP_SIZE_QWORD)", maskSize)
        return 0
    cdef unsigned long checksum(self, bytes data): # data is bytes
        cdef unsigned char c
        cdef unsigned long checksum
        checksum = 0
        for c in data:
            checksum = (checksum+c)&BITMASK_DWORD
        return checksum
    cdef unsigned long long decToBcd(self, unsigned char dec):
        cdef unsigned char bcd = int(str(dec), 16)
        return bcd
    cdef unsigned long long bcdToDec(self, unsigned char bcd):
        cdef unsigned char dec = int(hex(bcd)[2:], 10)
        return dec
    cdef unsigned long long reverseByteOrder(self, unsigned long value, unsigned char valueSize):
        cdef bytes data
        data = value.to_bytes(length=valueSize, byteorder="big")
        value = int.from_bytes(bytes=data, byteorder="little")
        return value
    cpdef object createTimer(self, float seconds, object timerFunc, unsigned char startIt):
        cpdef object timerObject
        timerObject = threading.Timer(seconds, timerFunc)
        if (startIt):
            timerObject.start()
        return timerObject
    cpdef object createThread(self, object threadFunc, unsigned char startIt):
        cpdef object threadObject
        threadObject = threading.Thread(target=threadFunc)
        if (startIt):
            threadObject.start()
        return threadObject


