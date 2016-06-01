
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

from threading import Thread


class HirnwichseException(Exception):
    pass


cdef class Misc:
    def __init__(self):
        pass
    cdef uint32_t checksum(self, bytes data) nogil: # data is bytes
        cdef uint8_t c
        cdef uint32_t checksum
        checksum = 0
        with gil:
            for c in data:
                checksum = <uint32_t>(checksum+c)
        return checksum
    cdef uint16_t decToBcd(self, uint16_t dec):
        return int(str(dec), 16)
    cdef uint16_t bcdToDec(self, uint16_t bcd):
        return int(hex(bcd)[2:], 10)
    cdef uint64_t reverseByteOrder(self, uint64_t value, uint8_t valueSize):
        cdef bytes data
        data = value.to_bytes(length=valueSize, byteorder="big")
        value = int.from_bytes(bytes=data, byteorder="little")
        return value
    cdef uint16_t calculateInterruptErrorcode(self, uint8_t num, uint8_t idt, uint8_t ext) nogil:
        if (idt):
            return (num << 3)|2|ext
        return (num & 0xfc)|ext
    cpdef object createThread(self, object threadFunc, uint8_t startIt):
        cpdef object threadObject
        threadObject = Thread(target=threadFunc)
        if (startIt):
            threadObject.start()
        return threadObject


