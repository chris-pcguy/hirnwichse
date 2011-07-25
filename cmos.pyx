import misc

##cimport numpy
##import numpy

cdef class Cmos:
    def __init__(self, object main):
        self.main = main
        self.cmosData = bytearray(256)
        ##self.cmosData = numpy.zeros(256, dtype=numpy.bytes_, order='C')
        self.cmosIndex = 0
    cpdef long inPort(self, long ioPortAddr, int dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr == 0x70):
                return self.cmosIndex
            elif (ioPortAddr == 0x71):
                return self.cmosData[self.cmosIndex]
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cpdef outPort(self, long ioPortAddr, data, int dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr == 0x70):
                self.cmosIndex = data
            elif (ioPortAddr == 0x71):
                self.cmosData[self.cmosIndex] = data
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cpdef run(self):
        self.main.platform.addReadHandlers((0x70, 0x71), self.inPort)
        self.main.platform.addWriteHandlers((0x70, 0x71), self.outPort)



