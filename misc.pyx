
include "globals.pxi"


class ChemuException(Exception):
    pass


cdef class Misc:
    cdef object main
    def __init__(self, object main):
        self.main = main
    def getBitMask(self, unsigned char size, unsigned char half=False, unsigned long long minus=1):
        cdef unsigned long long returnValue
        if (size == OP_SIZE_BYTE):
            if (half):
                returnValue = 0x80-minus
            else:
                returnValue = 0x100-minus
        elif (size == OP_SIZE_WORD):
            if (half):
                returnValue = 0x8000-minus
            else:
                returnValue = 0x10000-minus
        elif (size == OP_SIZE_DWORD):
            if (half):
                returnValue = 0x80000000-minus
            else:
                returnValue = 0x100000000-minus
        elif (size == OP_SIZE_QWORD):
            if (half):
                returnValue = 0x8000000000000000-minus
            else:
                returnValue = 0x10000000000000000-minus
        else:
            self.main.exitError("Misc::getBitMask: size {0:d} not in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD, OP_SIZE_QWORD)", size)
        return returnValue
    def checksum(self, bytes data): # data is bytes
        cdef unsigned long long checksum = 0
        for c in data:
            checksum = (checksum+c)&0xffffffff
        return checksum
    def decToBcd(self, unsigned char dec):
        cdef unsigned char bcd = int(str(dec), 16)
        return bcd
    def bcdToDec(self, unsigned char bcd):
        cdef unsigned char dec = int(hex(bcd)[2:], 10)
        return dec
    def reverseByteOrder(self, unsigned long value, unsigned char valueSize):
        cdef bytes data
        data = value.to_bytes(length=valueSize, byteorder="big")
        value = int.from_bytes(bytes=data, byteorder="little")
        return value


