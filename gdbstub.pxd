
from mm cimport Mm


cdef class GDBStubHandler:
    cpdef public object main, connHandler
    cdef public GDBStub gdbStub
    cdef bytes lastReadData, lastWrittenData, cmdStr
    cdef unsigned char cmdStrChecksum, cmdStrChecksumProof, readState
    cdef unsigned long cmdStrChecksumIndex
    cdef public unsigned char initSent
    cdef public unsigned long connId
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
    cpdef public object main, server
    cdef public GDBStubHandler gdbHandler
    cpdef object serverThread
    cpdef quitFunc(self)
    cpdef serveGDBStub(self)
    cpdef run(self)


