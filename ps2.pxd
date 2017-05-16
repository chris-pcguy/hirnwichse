
from libc.stdint cimport *

from hirnwichse_main cimport Hirnwichse
from pic cimport Pic
from registers cimport Registers
from cpu cimport Cpu
from posix.unistd cimport usleep


cdef class PS2:
    cdef Hirnwichse main
    cdef uint8_t ppcbT2Gate, ppcbT2Spkr, ppcbT2Out, kbdClockEnabled, lastUsedPort, lastUsedCmd, needWriteBytes, needWriteBytesMouse, \
                    irq1Requested, allowIrq1, irq12Requested, allowIrq12, sysf, translateScancodes, currentScancodesSet, scanningEnabled, \
                    inb, outb, auxb, batInProgress, timerPending, timeout, lastUsedController
    cdef bytes outBuffer, mouseBuffer
    cdef void resetInternals(self, uint8_t powerUp)
    cdef void initDevice(self)
    cdef void appendToOutBytesJustAppend(self, bytes data)
    cdef void appendToOutBytesMouse(self, bytes data)
    cdef void appendToOutBytes(self, bytes data)
    cdef void appendToOutBytesImm(self, bytes data)
    cdef void appendToOutBytesDoIrq(self, bytes data)
    cdef void setKeyboardRepeatRate(self, uint8_t data)
    cdef void keySend(self, uint8_t keyId, uint8_t keyUp)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize)
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef void setKbdClockEnable(self, uint8_t value)
    cdef void activateTimer(self)
    cdef uint8_t periodic(self, uint8_t usecDelta)
    cdef void timerFunc(self)
    cdef void initThread(self)
    cdef void run(self)


