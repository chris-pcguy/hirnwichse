
include "globals.pxi"


cdef class HirnwichseTest(Hirnwichse):
    cdef runThreadFunc(self):
        self.platform.run()
        (<Pic>self.platform.pic).cpuInstance = self.cpu
        (<Pic>self.platform.pic).setINTR = <SetINTR>self.cpu.setINTR
        (<IsaDma>self.platform.isadma).cpuInstance = self.cpu
        (<IsaDma>self.platform.isadma).setHRQ = <SetHRQ>self.cpu.setHRQ
        self.cpu.run(False)
        self.test1()
    cdef test1(self):
        cdef bytes data1
        cdef unsigned char data2, data3
        cdef unsigned short count = 512, ax = 0x02
        cdef unsigned int memAddr = 0x500
        data2 = (<Mm>self.mm).mmPhyReadValueUnsignedByte(memAddr)
        self.notice("data2=={0:#04x}", data2)
        data1 = b'\x49'*count
        (<Mm>self.mm).mmPhyWrite(memAddr, data1, count)
        (<PythonBios>self.platform.pythonBios).setRetError(False, 2)
        data3 = (<Mm>self.mm).mmPhyReadValueUnsignedByte(memAddr)
        self.notice("data3=={0:#04x}", data3)



