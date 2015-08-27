
from hirnwichse_main cimport Hirnwichse
from pic cimport Pic
from registers cimport Registers
from cpu cimport Cpu


cdef class PS2:
    cdef Hirnwichse main
    cdef public unsigned char ppcbT2Gate, ppcbT2Spkr, ppcbT2Out, kbdClockEnabled
    cdef unsigned char lastUsedPort, lastUsedCmd, needWriteBytes, needWriteBytesMouse, irq1Requested, allowIrq1, irq12Requested, allowIrq12, sysf, \
                        translateScancodes, currentScancodesSet, scanningEnabled, inb, outb, auxb, batInProgress, timerPending, timeout
    cdef bytes outBuffer, mouseBuffer
    cdef void resetInternals(self, unsigned char powerUp)
    cdef void initDevice(self)
    cdef void appendToOutBytesJustAppend(self, bytes data)
    cdef void appendToOutBytesMouse(self, bytes data)
    cdef void appendToOutBytes(self, bytes data)
    cdef void appendToOutBytesImm(self, bytes data)
    cdef void appendToOutBytesDoIrq(self, bytes data)
    cpdef setKeyboardRepeatRate(self, unsigned char data)
    cpdef keySend(self, unsigned char keyId, unsigned char keyUp)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void setKbdClockEnable(self, unsigned char value) nogil
    cdef void activateTimer(self) nogil
    cpdef unsigned char periodic(self, unsigned char usecDelta)
    cpdef timerFunc(self)
    cpdef initThread(self)
    cpdef run(self)


