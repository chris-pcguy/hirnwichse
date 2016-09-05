
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

from time import time


cdef unsigned int TEST_SIZE = OP_SIZE_DWORD

cdef class HirnwichseTest:
    def __init__(self):
        self.main = Hirnwichse()
        self.main.run(False)
        self.configSpace = ConfigSpace(128, self.main)
        self.configSpace.csResetData(0)
    cdef void func1(self) nogil:
        cdef double time1, timediff1
        cdef uint32_t a, i
        IF 1:
            with gil:
                time1 = time()
                for i in range(100000000):
                #for i in range(1):
                    #pass
                    #a = self.configSpace.csReadValueUnsigned(0, TEST_SIZE)
                    #self.main.cpu.saveCurrentInstPointer()
                    #a = self.main.cpu.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_CS]._union.word._union.rx
                    #a = self.main.cpu.registers.regs[CPU_REGISTER_EIP]._union.dword.erx
                    #a = self.main.cpu.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_SS]._union.word._union.rx
                    #a = self.main.cpu.registers.regs[CPU_REGISTER_ESP]._union.dword.erx
                    #a = self.main.cpu.registers.getCurrentOpcodeUnsignedByte()
                    self.main.cpu.opcodes.executeOpcode(0x00)
                timediff1 = time()-time1
                print("timediff1: {0:f}".format(timediff1))
        self.configSpace.csWriteValue(0, 0xdeadbeef, 4)
        self.configSpace.csWriteValue(4, 0xcafebabe, 4)
        self.configSpace.csWriteValue(8, 0x12345678, 4)
        self.configSpace.csWriteValue(12, 0xf00f0ff0, 4)
        with gil:
            for i in range(12):
                a = self.configSpace.csReadValueUnsigned(i, TEST_SIZE)
                print("msg_a{0:d}: {1:#010x}".format(i, a))
    cdef void run(self):
        self.func1()



