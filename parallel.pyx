
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"


cdef class Parallel:
    def __init__(self, Hirnwichse main):
        self.main = main
    cdef void reset(self):
        pass
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize):
        if (dataSize == OP_SIZE_BYTE):
            pass
        else:
            self.main.exitError("inPort: port 0x%02x with dataSize %u not supported.", ioPortAddr, dataSize)
        return BITMASK_BYTE
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize):
        if (dataSize == OP_SIZE_BYTE):
            pass
        else:
            self.main.exitError("outPort: port 0x%02x with dataSize %u not supported. (data: 0x%04x)", ioPortAddr, dataSize, data)
        return
    cdef void run(self):
        pass


