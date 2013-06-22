
from threading import Thread


class HirnwichseException(Exception):
    pass


cdef class Misc:
    def __init__(self, object main):
        self.main = main
    cdef unsigned int checksum(self, bytes data): # data is bytes
        cdef unsigned char c
        cdef unsigned int checksum
        checksum = 0
        for c in data:
            checksum = <unsigned int>(checksum+c)
        return checksum
    cdef unsigned short decToBcd(self, unsigned short dec):
        return int(str(dec), 16)
    cdef unsigned short bcdToDec(self, unsigned short bcd):
        return int(hex(bcd)[2:], 10)
    cdef unsigned int reverseByteOrder(self, unsigned int value, unsigned char valueSize):
        cdef bytes data
        data = value.to_bytes(length=valueSize, byteorder="big")
        value = int.from_bytes(bytes=data, byteorder="little")
        return value
    cdef unsigned char calculateInterruptErrorcode(self, unsigned char num, unsigned char idt, unsigned char ext):
        if (idt):
            return (num << 3)|2|ext
        return (num & 0xfc)|ext
    cpdef object createThread(self, object threadFunc, unsigned char startIt):
        cpdef object threadObject
        threadObject = Thread(target=threadFunc)
        if (startIt):
            threadObject.start()
        return threadObject


