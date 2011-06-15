import struct


CPU_REGISTER_EAX = 0
CPU_REGISTER_AX = 1
CPU_REGISTER_AH = 2
CPU_REGISTER_AL = 3
CPU_REGISTER_ECX = 4
CPU_REGISTER_CX = 5
CPU_REGISTER_CH = 6
CPU_REGISTER_CL = 7
CPU_REGISTER_EDX = 8
CPU_REGISTER_DX = 9
CPU_REGISTER_DH = 10
CPU_REGISTER_DL = 11
CPU_REGISTER_EBX = 12
CPU_REGISTER_BX = 13
CPU_REGISTER_BH = 14
CPU_REGISTER_BL = 15
CPU_REGISTER_ESP = 16
CPU_REGISTER_SP = 18
CPU_REGISTER_EBP = 20
CPU_REGISTER_BP = 22
CPU_REGISTER_ESI = 24
CPU_REGISTER_SI = 26
CPU_REGISTER_EDI = 28
CPU_REGISTER_DI = 30
CPU_REGISTER_EIP = 32
CPU_REGISTER_IP = 34
CPU_REGISTER_EFLAGS = 36
CPU_REGISTER_FLAGS = 38
CPU_REGISTER_CR0 = 40
CPU_REGISTER_CR2 = 44
CPU_REGISTER_CR3 = 48
CPU_REGISTER_CR4 = 52
CPU_REGISTER_LENGTH = 56


CPU_SEGMENT_CS = 100
CPU_SEGMENT_DS = 101
CPU_SEGMENT_ES = 102
CPU_SEGMENT_FS = 103
CPU_SEGMENT_GS = 104
CPU_SEGMENT_SS = 105


CPU_REGISTER_DWORD=(CPU_REGISTER_EAX,CPU_REGISTER_ECX,CPU_REGISTER_EDX,CPU_REGISTER_EBX,CPU_REGISTER_ESP,
                    CPU_REGISTER_EBP,CPU_REGISTER_ESI,CPU_REGISTER_EDI,CPU_REGISTER_EIP,CPU_REGISTER_EFLAGS,
                    CPU_REGISTER_CR0,CPU_REGISTER_CR2,CPU_REGISTER_CR3,CPU_REGISTER_CR4)

CPU_REGISTER_LWORD=(CPU_REGISTER_AX,CPU_REGISTER_CX,CPU_REGISTER_DX,CPU_REGISTER_BX,CPU_REGISTER_SP,
                    CPU_REGISTER_BP,CPU_REGISTER_SI,CPU_REGISTER_DI,CPU_REGISTER_IP,CPU_REGISTER_FLAGS)

CPU_REGISTER_HBYTE=(CPU_REGISTER_AH,CPU_REGISTER_CH,CPU_REGISTER_DH,CPU_REGISTER_BH)
CPU_REGISTER_LBYTE=(CPU_REGISTER_AL,CPU_REGISTER_CL,CPU_REGISTER_DL,CPU_REGISTER_BL)



class Register:
    def __init__(self):
        self.regs = bytearray(CPU_REGISTER_LENGTH)
    def readReg(self, regId, signedValue=False):
        aregId = regId//4
        if (regId in CPU_REGISTER_DWORD):
            return struct.unpack(((signedValue and ">i") or ">I"), self.regs[aregId:aregId+4])[0]
        elif (regId in CPU_REGISTER_LWORD):
            return struct.unpack(((signedValue and ">h") or ">H"), self.regs[aregId+2:aregId+4])[0]
        elif (regId in CPU_REGISTER_HBYTE):
            return struct.unpack(((signedValue and ">b") or ">B"), self.regs[aregId+2])[0]
        elif (regId in CPU_REGISTER_LBYTE):
            return struct.unpack(((signedValue and ">b") or ">B"), self.regs[aregId+3])[0]
        raise NameError("regId is unknown! ({0})".format(regId))
    def writeReg(self, regId, value):
        aregId = regId//4
        if (regId in CPU_REGISTER_DWORD):
            self.regs[aregId:aregId+4] = struct.pack(">I", value)
        elif (regId in CPU_REGISTER_LWORD):
            self.regs[aregId+2:aregId+4] = struct.pack(">H", value)
        elif (regId in CPU_REGISTER_HBYTE):
            self.regs[aregId+2] = value
        elif (regId in CPU_REGISTER_LBYTE):
            self.regs[aregId+3] = value
        else:
            raise NameError("regId is unknown! ({0})".format(regId))







