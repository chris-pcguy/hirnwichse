
from libc.stdint cimport *

from hirnwichse_main cimport Hirnwichse
from misc cimport Misc
from mm cimport Mm
from registers cimport Registers

cdef class GDBStubHandler:
    cpdef object connHandler
    cdef GDBStub gdbStub
    cdef bytes lastReadData, lastWrittenData, cmdStr
    cdef uint8_t cmdStrChecksum, cmdStrChecksumProof, readState, initSent
    cdef uint32_t cmdStrChecksumIndex, connId
    cdef void clearData(self)
    cdef void sendPacketType(self, bytes packetType)
    cdef void putPacket(self, bytes data)
    cdef void handleRead(self)
    cdef bytes byteToHex(self, uint8_t data)
    cdef bytes bytesToHex(self, bytes data)
    cdef bytes hexToByte(self, bytes data)
    cdef bytes hexToBytes(self, bytes data)
    cdef void sendInit(self, uint16_t gdbType)
    cdef void unhandledCmd(self, bytes data, uint8_t noMsg)
    cdef void handleCommand(self, bytes data)


cdef class GDBStub:
    cdef Hirnwichse main
    cpdef object server
    cdef GDBStubHandler gdbHandler
    cpdef quitFunc(self)
    cpdef serveGDBStub(self)
    cpdef run(self)


