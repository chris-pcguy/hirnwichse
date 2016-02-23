
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "cpu_globals.pxi"
include "globals.pxi"

import struct
from time import time

cdef class HirnwichseTest:
    def __init__(self):
        self.cf = self.pf = self.af = self.zf = self.sf = self.tf = \
          self.if_flag = self.df = self.of = self.iopl = self.nt = self.rf = self.vm = self.ac = \
          self.vif = self.vip = self.id = 0
    cdef void func1(self):
        cdef unsigned char a1[8]
        cdef unsigned char a2[8]
        cdef unsigned char c3[10]
        cdef unsigned char i
        cdef unsigned long int c1, c2
        cdef double b1, b2
        cdef long double b3
        cdef tuple t1, t2
        #a1 = [0x41, 0x50, 0x01, 0x7e, 0xc0, 0x00, 0x00, 0x00]
        #a2 = [0x41, 0x47, 0xff, 0xff, 0x80, 0x00, 0x00, 0x00]
        a1 = [0x00, 0x00, 0x00, 0xc0, 0x7e, 0x01, 0x50, 0x41]
        a2 = [0x00, 0x00, 0x00, 0x80, 0xff, 0xff, 0x47, 0x41]
        b1 = ((<double*>&a1)[0])
        b2 = ((<double*>&a2)[0])
        b3 = b1/b2
        t1 = b1.as_integer_ratio()
        t2 = b2.as_integer_ratio()
        c1 = t1[0]<<(64-t1[0].bit_length())
        c2 = t2[0]<<(64-t2[0].bit_length())
        memcpy(c3, (<unsigned char*>&b3), 10)
        print("test3_b1=={0:.12f}".format(b1))
        print("test3_b2=={0:.12f}".format(b2))
        print("test3_b3=={0:.12f}".format(b3))
        print("test3_t1=={0:s}".format(repr(t1)))
        print("test3_t2=={0:s}".format(repr(t2)))
        print("test3_c1=={0:s}".format(repr(struct.pack(">Q", c1))))
        print("test3_c2=={0:s}".format(repr(struct.pack(">Q", c2))))
        print("test3_c4=={0:s}".format("abcdef"[100:10000]))
        for i in range(10):
            print("test3_c3[{0:d}]=={1:#04x}".format(i, c3[i]))
        #print("test3_c3=={0:s}".format(repr(c3)))
    cdef void func2(self, unsigned char var1):
        if (var1 >= 0x00 and var1 <= 0x0f):
            pass
        elif (var1 >= 0x10 and var1 <= 0x1f):
            pass
        elif (var1 >= 0x20 and var1 <= 0x2f):
            pass
        elif (var1 >= 0x30 and var1 <= 0x3f):
            pass
        #
        elif ((var1 & 0xf0) == 0x40):
            pass
        elif (var1 >= 0x50 and var1 <= 0x5f):
            pass
        elif (var1 >= 0x60 and var1 <= 0x6f):
            pass
        elif (var1 >= 0x70 and var1 <= 0x7f):
            pass
        elif (var1 >= 0x80 and var1 <= 0x8f):
            pass
        elif (var1 >= 0x90 and var1 <= 0xff):
            pass
    cdef void func3(self):
        cdef unsigned long int i
        with nogil:
            for i in range(10000000):
                pass
    cdef void func4(self, unsigned int flags):
        cdef unsigned char ifEnabled
        """
        self.cf = (flags&FLAG_CF)!=0
        self.pf = (flags&FLAG_PF)!=0
        self.af = (flags&FLAG_AF)!=0
        self.zf = (flags&FLAG_ZF)!=0
        self.sf = (flags&FLAG_SF)!=0
        self.tf = (flags&FLAG_TF)!=0
        ifEnabled = ((not False) and ((flags&FLAG_IF)!=0))
        self.if_flag = (flags&FLAG_IF)!=0
        self.df = (flags&FLAG_DF)!=0
        self.of = (flags&FLAG_OF)!=0
        self.iopl = (flags>>12)&3
        self.nt = (flags&FLAG_NT)!=0
        self.rf = (flags&FLAG_RF)!=0
        self.vm = (flags&FLAG_VM)!=0
        self.ac = (flags&FLAG_AC)!=0
        self.vif = (flags&FLAG_VIF)!=0
        self.vip = (flags&FLAG_VIP)!=0
        self.id = (flags&FLAG_ID)!=0
        """
        #return (FLAG_REQUIRED | self.cf | (self.pf<<2) | (self.af<<4) | (self.zf<<6) | (self.sf<<7) | (self.tf<<8) | (self.if_flag<<9) | (self.df<<10) | \
        #  (self.of<<11) | (self.iopl<<12) | (self.nt<<14) | (self.rf<<16) | (self.vm<<17) | (self.ac<<18) | (self.vif<<19) | (self.vip<<20) | (self.id<<21))
        self.cf = flags&1
        self.pf = (flags>>2)&1
        self.af = (flags>>4)&1
        self.zf = (flags>>6)&1
        self.sf = (flags>>7)&1
        self.tf = (flags>>8)&1
        ifEnabled = ((not False) and ((flags>>9)&1))
        self.if_flag = (flags>>9)&1
        self.df = (flags>>10)&1
        self.of = (flags>>11)&1
        self.iopl = (flags>>12)&3
        self.nt = (flags>>14)&1
        self.rf = (flags>>16)&1
        self.vm = (flags>>17)&1
        self.ac = (flags>>18)&1
        self.vif = (flags>>19)&1
        self.vip = (flags>>20)&1
        self.id = (flags>>21)&1
    cpdef run(self):
        cdef unsigned int i
        cdef double time1, time2
        print("test1")
        #self.func1()
        time1 = time()
        for i in range(100000000):
            #self.func2(0x40)
            self.func4(BITMASK_DWORD)
        #self.func3()
        time2 = time()-time1
        print("test3: {0:f}".format(time2))
        print("test2")



