
from sys import exc_info, exit
from atexit import register
from socket import error as SocketError, IPPROTO_TCP, TCP_NODELAY
from socketserver import BaseRequestHandler, ThreadingMixIn, TCPServer

include "globals.pxi"
include "cpu_globals.pxi"

# with MUCH help from qemu's gdbstub.c


GDBSTUB_HOST = '127.0.0.1'
GDBSTUB_PORT = 1234
MAX_PACKET_SIZE = 4096 # 4 KB
MAX_PACKET_DATA_SIZE = (MAX_PACKET_SIZE//2)-2
RS_IDLE = 1
RS_GETLINE = 2
RS_CHKSUM1 = 3
RS_CHKSUM2 = 4


GDB_SIGNAL_0       = 0
GDB_SIGNAL_INT     = 2
GDB_SIGNAL_QUIT    = 3
GDB_SIGNAL_TRAP    = 5
GDB_SIGNAL_ABRT    = 6
GDB_SIGNAL_ALRM    = 14
GDB_SIGNAL_IO      = 23
GDB_SIGNAL_XCPU    = 24
GDB_SIGNAL_UNKNOWN = 143

PACKET_NONE = b''
PACKET_ACK  = b'+'
PACKET_NACK = b'-'


###GDB_NUM_REGISTERS = ##### 308 # i386
GDB_NUM_REGISTERS = 77
SEND_REGHEX_SIZE = 616


cdef class GDBStubHandler:
    def __init__(self, object main, GDBStub gdbStub):
        self.connHandler = None
        self.main = main
        self.gdbStub = gdbStub
        self.connId = 0
        self.initSent = False
        self.lastWrittenData = bytes()
        self.clearData()
    cdef clearData(self):
        self.lastReadData = bytes()
        self.cmdStr = bytes()
        self.cmdStrChecksum = 0
        self.cmdStrChecksumProof = 0
        self.readState = RS_IDLE
    cdef sendPacketType(self, bytes packetType):
        self.connHandler.request.send(packetType)
        #self.connHandler.request.flush()
    cdef putPacket(self, bytes data):
        cdef bytes dataFull, dataChecksum
        if (self.connHandler):
            if (hasattr(self.connHandler, 'request') and self.connHandler.request):
                dataChecksum = self.byteToHex(<unsigned char>(<Misc>self.main.misc).checksum(data))
                dataFull = b'$'
                dataFull += data
                dataFull += b'#'+dataChecksum
                self.lastWrittenData = data
                self.connHandler.request.send(dataFull)
                #self.connHandler.request.flush()
            else:
                self.main.printMsg('GDBStubHandler::putPacket: connHandler.request is None.')
        else:
            self.main.printMsg('GDBStubHandler::putPacket: connHandler is None.')

    cdef handleRead(self):
        cdef bytes tempStr
        cdef unsigned char c
        if (self.connHandler):
            if (hasattr(self.connHandler, 'request') and self.connHandler.request):
                while (not self.main.quitEmu and self.main.cpu.debugHalt):
                    tempStr = self.connHandler.request.recv(MAX_PACKET_SIZE)
                    if (len(self.lastWrittenData)):
                        if (tempStr.startswith(b'-')):
                            self.main.printMsg("GDBStubHandler::handleRead: GOT NACK!!")
                            self.putPacket(self.lastWrittenData)
                            self.clearData()
                            return
                        elif (tempStr.startswith(b'+')):
                            ##self.main.debug("GDBStubHandler::handleRead: got ack.")
                            self.lastWrittenData = bytes()
                            if (len(tempStr) >= 2):
                                tempStr = tempStr[1:]
                    self.clearData()
                    #else:
                    #    self.main.printMsg("handleRead: tempStr doesn't start with b'-' or b'+'. (tempStr: {0:s})", repr(tempStr))
                    self.lastReadData = tempStr
                    for c in self.lastReadData:
                        #self.main.printMsg("c: {0:#04x}, readState: {1:#04x}", c, self.readState)
                        if (self.readState == RS_IDLE):
                            if (c == ord(b'$')):
                                self.readState = RS_GETLINE
                                self.cmdStr = self.lastWrittenData = bytes()
                        elif (self.readState == RS_GETLINE):
                            if (c == ord(b'#')):
                                self.readState = RS_CHKSUM1
                                continue
                            self.cmdStr += bytes([c])
                        elif (self.readState == RS_CHKSUM1):
                            self.cmdStrChecksumProof = int(bytes([c]), 16)<<4
                            self.readState = RS_CHKSUM2
                        elif (self.readState == RS_CHKSUM2):
                            self.cmdStrChecksumProof |= int(bytes([c]), 16)
                            self.cmdStrChecksum = <unsigned char>(<Misc>self.main.misc).checksum(self.cmdStr)
                            if (self.cmdStrChecksum != self.cmdStrChecksumProof):
                                self.main.printMsg("GDBStubHandler::handleRead: SEND NACK!")
                                self.sendPacketType(PACKET_NACK)
                                self.clearData()
                                return
                            ##self.main.debug("GDBStubHandler::handleRead: send ack.")
                            self.sendPacketType(PACKET_ACK)
                            self.handleCommand(self.cmdStr)
                            self.clearData()
                            return
                        else:
                            self.main.printMsg("GDBStubHandler::handleRead: unknown case.")
            else:
                self.main.printMsg('GDBStubHandler::handleRead: connHandler.request is None.')
        else:
            self.main.printMsg('GDBStubHandler::handleRead: connHandler is None.')
    cdef bytes byteToHex(self, unsigned char data): # data is unsigned char, output==bytes
        cdef bytes returnValue = '{0:02x}'.format(data).encode()
        return returnValue
    cdef bytes bytesToHex(self, bytes data): # data is bytes, output==bytes
        cdef bytes returnValue
        cdef unsigned char c
        returnValue = bytes()
        for c in data:
            returnValue += self.byteToHex(c)
        return returnValue
    cdef bytes hexToByte(self, bytes data): # data is bytes, output==bytes
        cdef bytes returnValue = bytes([int(data, 16)])
        return returnValue
    cdef bytes hexToBytes(self, bytes data): # data is bytes, output==bytes
        cdef bytes returnValue = bytes()
        cdef unsigned int i = 0
        cdef unsigned int dataLen = len(data)
        if ((dataLen % 2) != 0):
            self.main.exitError('GDBStubHandler::hexToBytes: (dataLen % 2) != 0')
        while (i < dataLen):
            returnValue += self.hexToByte(data[i:i+2])
            i += 2
        return returnValue
    cdef sendInit(self, unsigned short gdbType):
        self.putPacket('T{0:02x}thread:{1:02x};'.format(gdbType, self.connId).encode())
    cdef unhandledCmd(self, bytes data, unsigned char noMsg):
        if (not noMsg):
            self.main.printMsg('GDBStubHandler::handleCommand: unhandled cmd: {0:s}', repr(data))
        self.putPacket(bytes())
    cdef handleCommand(self, bytes data):
        cdef unsigned int memAddr, memLength, blockSize, regVal
        cdef signed int threadNum, res_signal, res_thread, signal, thread
        cdef unsigned short regOffset, maxRegNum, currRegNum
        cdef unsigned char cpuType, singleStepOn, res
        cdef list memList, actionList
        cdef bytes currData, hexToSend, action
        if (not len(data)):
            self.main.printMsg("INFO: GDBStubHandler::handleCommand: data is empty, don't do anything.")
            return
        if (data.lower()[0] == ord(b'q')):
            if (len(data) >= 10 and data[1:].startswith(b'Supported')):
                #self.putPacket('PacketSize={0:x};qXfer:features:read+'.format(MAX_PACKET_SIZE).encode())
                self.putPacket('PacketSize={0:x}'.format(MAX_PACKET_SIZE).encode())
            elif (len(data) >= 7 and data[1:].startswith((b'Attach', b'TStatus'))):
                self.putPacket(bytes())
            elif (len(data) == 2 and data[1] == ord(b'C')):
                self.putPacket(b'QC1')
            else:
                self.unhandledCmd(data, False)
        elif (data.startswith(b'H')):
            cpuType = data[1]
            threadNum = int(data[2:], 16)
            self.putPacket(b'OK')
        elif (data == b'?'):
            self.sendInit(GDB_SIGNAL_TRAP)
        elif (data == b'k'):
            self.main.quitFunc()
            self.main.exitError("GDBStubHandler::handleCommand: Terminated by GDBStub.", errorExitCode=0, exitNow=False)
            self.gdbStub.server.shutdown()
            return
        elif (data == b'D'):
            self.main.cpu.debugSingleStep = False
            self.main.cpu.debugHalt = False
            self.putPacket(b'OK')
        elif (data == b'g'):
            currRegNum = 0
            maxRegNum = GDB_NUM_REGISTERS
            hexToSend = bytes()
            while (currRegNum < maxRegNum):
                regOffset = ((CPU_MIN_REGISTER//5)+currRegNum)*8
                currData = (<ConfigSpace>self.main.cpu.registers.regs).csRead(regOffset+4, OP_SIZE_DWORD)
                hexToSend += self.bytesToHex(bytes(currData[::-1]))
                currRegNum += 1
            if (len(hexToSend) != SEND_REGHEX_SIZE):
                self.main.printMsg('GDBStubHandler::handleCommand: hexToSend_len({0:d}) != SEND_REGHEX_SIZE({1:d})', len(hexToSend), SEND_REGHEX_SIZE)
            self.putPacket(hexToSend)
        elif (data.startswith(b'G')):
            currRegNum = 0
            maxRegNum = GDB_NUM_REGISTERS
            data = data[1:]
            while (currRegNum < maxRegNum):
                dataOffset = currRegNum*8
                if (currRegNum*5 >= CPU_MAX_REGISTER_WO_CR):
                    break
                regOffset = ((CPU_MIN_REGISTER//5)+currRegNum)*8
                currData = self.hexToBytes(data[dataOffset:dataOffset+8]) # currData is bytes/DWORD
                if (len(currData) != 4):
                    self.main.exitError("GDBStubHandler::handleCommand: len(currData)!=4; currData isn't DWORD.")
                    return
                regVal = int.from_bytes(bytes=currData, byteorder="little", signed=False)
                self.main.cpu.registers.regs.csWriteValueBE(regOffset, regVal, OP_SIZE_QWORD)
                currRegNum += 1
            self.putPacket(b'OK')
        elif (data.startswith(b'm')):
            memList = data[1:].split(b',')
            memAddr = int(memList[0], 16)
            memLength = int(memList[1], 16)
            hexToSend = bytes()
            while (memLength != 0):
                blockSize = min(memLength, MAX_PACKET_DATA_SIZE)
                if ((<Mm>self.main.mm).mmGetSingleArea(memAddr, blockSize)):
                    currData = (<Mm>self.main.mm).mmPhyRead(memAddr, blockSize)
                else:
                    currData = b'\x00'*blockSize
                hexToSend = self.bytesToHex(currData)
                self.putPacket(hexToSend)
                memLength -= blockSize
                memAddr   += blockSize
        elif (data.startswith(b'v')):
            if (data.startswith(b'vCont')):
                if (data == b'vCont?'):
                    self.putPacket(b'vCont;c;C;s;S')
                    return
                actionList = data[6:].split(b';')
                res, res_signal, res_thread, thread = 0, 0, 0, 0
                for action in actionList:
                    signal = 0
                    if (not action):
                        res = 0
                        return
                    if (action[0] in (ord(b'C'), ord(b'S')) ):
                        signal = int(action[1:], 16)
                    elif (action[0] not in (ord(b'c'), ord(b's')) ):
                        res = 0
                        return
                    if (len(action)>1 and action[1] == ord(b':')):
                        if (len(action)>2):
                            thread = int(action[2:], 16)
                        else:
                            self.main.printMsg('GDBStubHandler::handleCommand: v: action isn\'t int enough for threadnum')
                    action = action.lower()
                    if (not res or (res == ord(b'c') and action == ord(b's'))):
                        res = action[0]
                        res_signal = signal
                        res_thread = thread
                if (res):
                    if (signal):
                        self.main.printMsg('GDBStubHandler::handleCommand: v: signal not implemented')
                    singleStepOn = res==ord(b's')
                    self.main.cpu.debugSingleStep = singleStepOn
                    self.main.cpu.debugHalt = singleStepOn
                    if (singleStepOn):
                        self.sendInit(GDB_SIGNAL_TRAP)
            else:
                self.unhandledCmd(data, False)
        elif (data.startswith(b'p')): # TODO
            self.unhandledCmd(data, True)
        elif (data.startswith(b'P')): # TODO
            self.unhandledCmd(data, True)
        else:
            self.unhandledCmd(data, False)

class ThreadedTCPRequestHandler(BaseRequestHandler):
    def handle(self):
        self.gdbHandler = (<GDBStubHandler>self.server.gdbHandler)
        (<GDBStubHandler>self.gdbHandler).connHandler = self
        (<GDBStubHandler>self.gdbHandler).connId += 1
        try:
            (<GDBStubHandler>self.gdbHandler).main.cpu.debugHalt = True
            (<GDBStubHandler>self.gdbHandler).main.cpu.debugSingleStep = False
            (<GDBStubHandler>self.gdbHandler).clearData()
            if (not (<GDBStubHandler>self.gdbHandler).initSent):
                (<GDBStubHandler>self.gdbHandler).sendInit(GDB_SIGNAL_INT)
                (<GDBStubHandler>self.gdbHandler).initSent = True
            while (not (<GDBStubHandler>self.gdbHandler).main.quitEmu and (<GDBStubHandler>self.gdbHandler).main.cpu.debugHalt):
                #(<GDBStubHandler>self.gdbHandler).main.printMsg("handle::read.")
                (<GDBStubHandler>self.gdbHandler).handleRead()
        except (SystemExit, KeyboardInterrupt):
            (<GDBStubHandler>self.gdbHandler).main.quitEmu = True
            (<GDBStubHandler>self.gdbHandler).gdbStub.server.shutdown()


class ThreadedTCPServer(ThreadingMixIn, TCPServer):
    pass



cdef class GDBStub:
    def __init__(self, object main):
        self.main = main
        self.server = None
        self.gdbHandler = None
        try:
            self.server = ThreadedTCPServer((GDBSTUB_HOST, GDBSTUB_PORT), ThreadedTCPRequestHandler, bind_and_activate=False)
            self.gdbHandler = GDBStubHandler(self.main, self)
            self.server.gdbHandler = self.gdbHandler
            self.server.allow_reuse_address = True
            self.server.socket.setsockopt(IPPROTO_TCP, TCP_NODELAY, True)
            self.server.server_bind()
            self.server.server_activate()
            register(self.quitFunc)
        except SocketError:
            print(exc_info())
            self.main.printMsg("GDBStub::__init__: socket exception.")
            self.server = None
            self.gdbHandler = None
        except (SystemExit, KeyboardInterrupt):
            print(exc_info())
            self.main.quitEmu = True
            self.main.printMsg("GDBStub::__init__: (SystemExit, KeyboardInterrupt) exception.")
            self.server = None
            self.gdbHandler = None
        except:
            print(exc_info())
            self.main.printMsg("GDBStub::__init__: else exception.")
            self.server = None
            self.gdbHandler = None
    cpdef quitFunc(self):
        if (self.server):
            self.server.shutdown()
    cpdef serveGDBStub(self):
        try:
            if (self.server):
                self.server.serve_forever()
        except (SystemExit, KeyboardInterrupt):
            self.main.quitEmu = True
            if (self.server):
                self.server.shutdown()
        except:
            print(exc_info())
    cpdef run(self):
        try:
            (<Misc>self.main.misc).createThread(self.serveGDBStub, True)
        except (SystemExit, KeyboardInterrupt):
            self.main.quitEmu = True
            exit(self.main.exitCode)



