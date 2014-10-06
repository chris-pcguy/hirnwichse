
from pic cimport Pic
from registers cimport Registers
from cpu cimport Cpu


cdef class PS2:
    cpdef object main
    cdef public unsigned char ppcbT2Gate, ppcbT2Spkr, ppcbT2Out, kbdClockEnabled
    cdef unsigned char lastUsedPort, lastUsedCmd, needWriteBytes, irq1Requested, allowIrq1, sysf, \
                        translateScancodes, currentScancodesSet, scanningEnabled, inb, outb, batInProgress, timerPending
    cdef bytes outBuffer
    cdef void resetInternals(self, unsigned char powerUp)
    cdef void initDevice(self)
    cdef void appendToOutBytesJustAppend(self, bytes data)
    cdef void appendToOutBytes(self, bytes data)
    cdef void appendToOutBytesImm(self, bytes data)
    cdef void appendToOutBytesDoIrq(self, bytes data)
    cpdef setKeyboardRepeatRate(self, unsigned char data)
    cpdef keySend(self, unsigned char keyId, unsigned char keyUp)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void setKbdClockEnable(self, unsigned char value)
    cpdef activateTimer(self)
    cpdef unsigned char periodic(self, unsigned char usecDelta)
    cpdef timerFunc(self)
    cpdef initThread(self)
    cpdef run(self)


