
from misc cimport Misc
from mm cimport Mm, MmArea
from registers cimport Registers

cdef class GDBStubHandler:
    cpdef object main, connHandler
    cdef GDBStub gdbStub
    cdef bytes lastReadData, lastWrittenData, cmdStr
    cdef unsigned char cmdStrChecksum, cmdStrChecksumProof, readState, initSent
    cdef unsigned int cmdStrChecksumIndex, connId
    cdef clearData(self)
    cdef sendPacketType(self, bytes packetType)
    cdef putPacket(self, bytes data)
    cdef handleRead(self)
    cdef bytes byteToHex(self, unsigned char data)
    cdef bytes bytesToHex(self, bytes data)
    cdef bytes hexToByte(self, bytes data)
    cdef bytes hexToBytes(self, bytes data)
    cdef sendInit(self, unsigned short gdbType)
    cdef unhandledCmd(self, bytes data, unsigned char noMsg)
    cdef handleCommand(self, bytes data)


cdef class GDBStub:
    cpdef object main, server
    cdef GDBStubHandler gdbHandler
    cpdef quitFunc(self)
    cpdef serveGDBStub(self)
    cpdef run(self)


