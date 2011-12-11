
import misc, mm, registers, atexit, socket, threading, socketserver, sys

include "globals.pxi"

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
    cpdef public object main, gdbStub, connHandler
    cdef bytes lastReadData, lastWrittenData, cmdStr
    cdef unsigned char cmdStrChecksum, cmdStrChecksumProof, readState
    cdef unsigned long cmdStrChecksumIndex
    cdef public unsigned char initSent
    cdef public unsigned long connId
    def __init__(self, object main, object gdbStub):
        self.connHandler = None
        self.main = main
        self.gdbStub = gdbStub
        self.connId = 0
        self.initSent = False
        self.lastWrittenData = bytes()
        self.clearData()
    cpdef clearData(self):
        self.lastReadData = bytes()
        self.cmdStr = bytes()
        self.cmdStrChecksum = 0
        self.cmdStrChecksumProof = 0
        self.readState = RS_IDLE
    cpdef sendPacketType(self, bytes packetType):
        self.connHandler.request.send(packetType)
        #self.connHandler.request.flush()
    cpdef putPacket(self, bytes data):
        cdef bytes dataFull, dataChecksum
        if (self.connHandler):
            if (hasattr(self.connHandler, 'request') and self.connHandler.request):
                dataChecksum = self.byteToHex(self.main.misc.checksum(data)&0xff)
                dataFull = b'$'
                dataFull += data
                dataFull += b'#'+dataChecksum
                self.lastWrittenData = data
                self.connHandler.request.send(dataFull)
                #self.connHandler.request.flush()
            else:
                self.main.printMsg('GDBStubHandler: putPacket: connHandler.request is NULL.')
        else:
            self.main.printMsg('GDBStubHandler: putPacket: connHandler is NULL.')

    cpdef handleRead(self):
        cdef bytes tempStr, c
        if (self.connHandler):
            if (hasattr(self.connHandler, 'request') and self.connHandler.request):
                while (not self.main.quitEmu and self.main.cpu.debugHalt):
                    tempStr = self.connHandler.request.recv(MAX_PACKET_SIZE)
                    if (len(self.lastWrittenData)):
                        if (tempStr.startswith(b'-')):
                            self.main.printMsg("handleRead: GOT NACK!!")
                            self.putPacket(self.lastWrittenData)
                            self.clearData()
                            return
                        elif (tempStr.startswith(b'+')):
                            self.main.printMsg("handleRead: got ack.")
                            self.lastWrittenData = bytes()
                            if (len(tempStr) >= 2):
                                tempStr = tempStr[1:]
                    self.clearData()
                    #else:
                    #    self.main.printMsg("handleRead: tempStr doesn't start with b'-' or b'+'. (tempStr: {0:s})", repr(tempStr))
                    self.lastReadData = tempStr
                    for c in self.lastReadData:
                        if (self.readState == RS_IDLE):
                            if (c == b'$'):
                                self.readState = RS_GETLINE
                                self.cmdStr = self.lastWrittenData = bytes()
                        elif (self.readState == RS_GETLINE):
                            if (c == b'#'):
                                self.readState = RS_CHKSUM1
                                return
                            self.cmdStr += c
                        elif (self.readState == RS_CHKSUM1):
                            self.cmdStrChecksumProof = int(c, 16)<<4
                            self.readState = RS_CHKSUM2
                        elif (self.readState == RS_CHKSUM2):
                            self.cmdStrChecksumProof |= int(c, 16)
                            self.cmdStrChecksum = self.main.misc.checksum(self.cmdStr)&0xff
                            if (self.cmdStrChecksum != self.cmdStrChecksumProof):
                                self.main.printMsg("handleRead: SEND NACK!")
                                self.sendPacketType(PACKET_NACK)
                                self.clearData()
                                return
                            self.main.printMsg("handleRead: send ack.")
                            self.sendPacketType(PACKET_ACK)
                            self.handleCommand(self.cmdStr)
                            self.clearData()
                            return
                        else:
                            self.main.printMsg("GDBStubHandler::handleRead: unknown case.")
            else:
                self.main.printMsg('GDBStubHandler: handleRead: connHandler.request is NULL.')
        else:
            self.main.printMsg('GDBStubHandler: handleRead: connHandler is NULL.')
    cpdef bytes byteToHex(self, unsigned char data): # data is unsigned char, output==bytes
        cdef bytes returnValue = '{0:02x}'.format(data).encode()
        return returnValue
    cpdef bytes bytesToHex(self, bytes data): # data is bytes, output==bytes
        cdef bytes returnValue, c
        returnValue = bytes()
        for c in data:
            returnValue += self.byteToHex(c)
        return returnValue
    cpdef bytes hexToByte(self, bytes data): # data is bytes, output==bytes
        cdef bytes returnValue = bytes([int(data, 16)])
        return returnValue
    cpdef bytes hexToBytes(self, bytes data): # data is bytes, output==bytes
        cdef bytes returnValue = bytes()
        cdef unsigned long i = 0
        cdef unsigned long dataLen = len(data)
        if ((dataLen % 2) != 0):
            self.main.exitError('GDBStub::hexToBytes: (dataLen % 2) != 0')
        while (i < dataLen):
            returnValue += self.hexToByte(data[i:i+2])
            i += 2
        return returnValue
    cpdef sendInit(self, unsigned short gdbType):
        self.putPacket('T{0:02x}thread:{1:02x};'.format(gdbType, self.connId).encode())
    cpdef unhandledCmd(self, bytes data, unsigned char noMsg):
        if (not noMsg):
            self.main.printMsg('handleCommand: unhandled cmd: {0:s}', repr(data))
        self.putPacket(bytes())
    cpdef handleCommand(self, bytes data):
        cdef unsigned long memAddr, memLength, blockSize, regVal
        cdef long threadNum, res_signal, res_thread, signal, thread
        cdef unsigned short minRegNum, maxRegNum, currRegNum
        cdef unsigned char cpuType, singleStepOn, res
        cdef list memList, actionList
        cdef bytes currData, hexToSend, action
        if (not len(data)):
            self.main.printMsg("INFO: handleCommand: data is empty, don't do anything.")
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
            self.main.exitError("Terminated by GDBStub.", errorExitCode=0, exitNow=False)
            self.gdbStub.server.shutdown()
            return
        elif (data == b'D'):
            self.main.cpu.debugSingleStep = False
            self.main.cpu.debugHalt = False
            self.putPacket(b'OK')
        elif (data == b'g'):
            minRegNum = 0
            maxRegNum = GDB_NUM_REGISTERS
            currRegNum = minRegNum
            hexToSend = bytes()
            currData = bytes(self.main.cpu.registers.regs.csData)
            while (currRegNum < maxRegNum):
                regOffset = ((CPU_MIN_REGISTER//5)+currRegNum)*8
                hexToSend += self.bytesToHex(bytes(currData[regOffset+4:regOffset+8][::-1]))
                currRegNum += 1
            if (len(hexToSend) != SEND_REGHEX_SIZE):
                self.main.printMsg('handleCommand: len(hexToSend) != SEND_REGHEX_SIZE')
            self.putPacket(hexToSend)
        elif (data.startswith(b'G')):
            minRegNum = 0
            maxRegNum = GDB_NUM_REGISTERS
            currRegNum = minRegNum
            data = data[1:]
            while (currRegNum < maxRegNum):
                dataOffset = currRegNum*8
                if (currRegNum*5 >= CPU_MAX_REGISTER_WO_CR):
                    break
                regOffset = ((CPU_MIN_REGISTER//5)+currRegNum)*8
                currData = self.hexToBytes(data[dataOffset:dataOffset+8]) # currData is bytes/DWORD
                if (len(currData) != 4):
                    self.main.exitError("GDB::handleCommand: len(currData)!=4; currData isn't DWORD.")
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
                if (self.main.mm.mmGetSingleArea(memAddr, blockSize)):
                    currData = self.main.mm.mmPhyRead(memAddr, blockSize)
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
                            self.main.printMsg('handleCommand: v: action isn\'t long enough for threadnum')
                    action = action.lower()
                    if (not res or (res == ord(b'c') and action == ord(b's'))):
                        res = action[0]
                        res_signal = signal
                        res_thread = thread
                if (res):
                    if (signal):
                        self.main.printMsg('handleCommand: v: signal not implemented')
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

class ThreadedTCPRequestHandler(socketserver.BaseRequestHandler):
    def handle(self):
        self.gdbHandler = self.server.gdbHandler
        self.gdbHandler.connHandler = self
        self.gdbHandler.connId += 1
        try:
            self.gdbHandler.main.cpu.debugHalt = True
            self.gdbHandler.main.cpu.debugSingleStep = False
            self.gdbHandler.clearData()
            if (not self.gdbHandler.initSent):
                self.gdbHandler.sendInit(GDB_SIGNAL_INT)
                self.gdbHandler.initSent = True
            while (not self.gdbHandler.main.quitEmu and self.gdbHandler.main.cpu.debugHalt):
                #self.gdbHandler.main.printMsg("handle::read.")
                self.gdbHandler.handleRead()
        except (SystemExit, KeyboardInterrupt):
            self.gdbHandler.gdbStub.server.shutdown()


class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    pass



cdef class GDBStub:
    cpdef public object main, server, gdbHandler
    cpdef object serverThread
    def __init__(self, object main):
        self.main = main
        self.server = ThreadedTCPServer((GDBSTUB_HOST, GDBSTUB_PORT), ThreadedTCPRequestHandler, bind_and_activate=False)
        self.gdbHandler = GDBStubHandler(self.main, self)
        self.server.gdbHandler = self.gdbHandler
        self.server.allow_reuse_address = True
        self.server.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, True)
        self.server.server_bind()
        self.server.server_activate()
        self.serverThread = None
        atexit.register(self.quitFunc)
    cpdef quitFunc(self):
        if (self.server):
            self.server.shutdown()
    cpdef serveGDBStub(self):
        try:
            self.server.serve_forever()
        except (SystemExit, KeyboardInterrupt):
            self.server.shutdown()
        except:
            print(sys.exc_info())
    cpdef run(self):
        try:
            self.main.misc.createThread(self.serveGDBStub, True)
        except (SystemExit, KeyboardInterrupt):
            sys.exit(self.main.exitCode)



