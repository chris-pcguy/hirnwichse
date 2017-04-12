
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

from time import time

include "globals.pxi"
#include "cpu_globals.pxi"

cdef unsigned int TEST_SIZE = OP_SIZE_DWORD

cdef class HirnwichseTest:
    def __init__(self):
        self.main = Hirnwichse()
        self.main.run(False)
        #self.configSpace = ConfigSpace(128, self.main)
        #self.configSpace.csResetData(0)
        #pass
    cdef void func1(self):
        cdef double time1, timediff1
        cdef uint32_t i
        cdef uint32_t operOp1, operOp2, operSumDword
        cdef uint64_t operSum
        IF 0:
            time1 = time()
            for i in range(100000000):
            #for i in range(1):
                pass
            timediff1 = time()-time1
            print("timediff1: {0:f}".format(timediff1))
        IF 0:
            operOp1 = 0x66666667
            operOp2 = 0x03000000
            operSum = <uint64_t>(<int64_t><int32_t>operOp1*<int32_t>operOp2)
            print("IMUL DWORD test2 (operSumLow : {0:#018x})".format(operSum))
            print("IMUL DWORD test2 (operSumHigh: {0:#010x})".format(operSum>>32))
        IF 0:
            operSumDword = self.main.mm.mmPhyReadValueUnsignedDword(0xfee00030)
            print("0xfee00030_val == {0:#010x}".format(operSumDword))
        IF 0:
            operSumDword = self.configSpace.csReadValueUnsignedDword(0x24)
            print("cmos_0x24_dword_1 == {0:#010x}".format(operSumDword))
            #self.configSpace.csWriteValue(0x24, 0x12345678, OP_SIZE_DWORD)
            self.configSpace.csWriteValueDword(0x24, 0x12345678)
            operSumDword = self.configSpace.csReadValueUnsignedDword(0x24)
            print("cmos_0x24_dword_2 == {0:#010x}".format(operSumDword))
        IF 1:
            print("val0: {0:#010x}".format(self.main.cpu.registers.readFromCacheUnsigned(OP_SIZE_DWORD)))
            print("val1: {0:#010x}".format(self.main.cpu.registers.readFromCacheAddUnsigned(OP_SIZE_BYTE)))
            print("val2: {0:#010x}".format(self.main.cpu.registers.readFromCacheAddUnsigned(OP_SIZE_BYTE)))
            print("val3: {0:#010x}".format(self.main.cpu.registers.readFromCacheAddUnsigned(OP_SIZE_BYTE)))
            print("val4: {0:#010x}".format(self.main.cpu.registers.readFromCacheAddUnsigned(OP_SIZE_BYTE)))
    cpdef void run(self):
        self.func1()



