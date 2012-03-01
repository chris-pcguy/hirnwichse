
from pic cimport Pic
from segments cimport Segments
from registers cimport Registers
from cpu cimport Cpu


cdef class PS2:
    cpdef public object main
    cdef public unsigned char ppcbT2Nibble, ppcbT2Done, kbdClockEnabled
    cdef unsigned char lastUsedPort, lastUsedCmd, needWriteBytes, irq1Requested, allowIrq1, sysf, \
                        translateScancodes, currentScancodesSet, scanningEnabled, outb, batInProgress, timerPending
    cdef bytes outBuffer
    cdef void resetInternals(self, unsigned char powerUp)
    cdef void initDevice(self)
    cdef void appendToOutBytesJustAppend(self, bytes data)
    cdef void appendToOutBytes(self, bytes data)
    cdef void appendToOutBytesImm(self, bytes data)
    cdef void appendToOutBytesDoIrq(self, bytes data)
    cpdef setKeyboardRepeatRate(self, unsigned char data)
    cpdef keySend(self, unsigned char keyId, unsigned char keyUp)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef void setKbdClockEnable(self, unsigned char value)
    cpdef activateTimer(self)
    cpdef unsigned char periodic(self, unsigned char usecDelta)
    cpdef timerFunc(self)
    cpdef initThread(self)
    cpdef run(self)


