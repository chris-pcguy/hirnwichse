
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

from time import time


cdef unsigned int TEST_SIZE = OP_SIZE_DWORD

cdef class HirnwichseTest:
    def __init__(self):
        #self.main = Hirnwichse()
        #self.main.run(False)
        #self.configSpace = ConfigSpace(128, self.main)
        #self.configSpace.csResetData(0)
        pass
    cdef void func1(self) nogil:
        cdef double time1, timediff1
        cdef uint32_t i
        cdef uint32_t operOp1, operOp2
        cdef uint64_t operSum
        IF 0:
            with gil:
                time1 = time()
                for i in range(100000000):
                #for i in range(1):
                    pass
                timediff1 = time()-time1
                print("timediff1: {0:f}".format(timediff1))
        with gil:
            operOp1 = 0x66666667
            operOp2 = 0x03000000
            operSum = <uint64_t>(<int64_t><int32_t>operOp1*<int32_t>operOp2)
            print("IMUL DWORD test2 (operSumLow : {0:#018x})".format(operSum))
            print("IMUL DWORD test2 (operSumHigh: {0:#010x})".format(operSum>>32))
    cpdef void run(self):
        self.func1()



