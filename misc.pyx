
from threading import Thread, Timer
from random import randint


class ChemuException(Exception):
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
    cdef unsigned long int decToBcd(self, unsigned char dec):
        cdef unsigned char bcd = int(str(dec), 16)
        return bcd
    cdef unsigned long int bcdToDec(self, unsigned char bcd):
        cdef unsigned char dec = int(hex(bcd)[2:], 10)
        return dec
    cdef unsigned long int reverseByteOrder(self, unsigned int value, unsigned char valueSize):
        cdef bytes data
        data = value.to_bytes(length=valueSize, byteorder="big")
        value = int.from_bytes(bytes=data, byteorder="little")
        return value
    cpdef object createThread(self, object threadFunc, unsigned char startIt):
        cpdef object threadObject
        threadObject = Thread(target=threadFunc)
        if (startIt):
            threadObject.start()
        return threadObject


