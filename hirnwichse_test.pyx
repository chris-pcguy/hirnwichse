
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

import struct
from time import time

cdef class HirnwichseTest:
    def __init__(self):
        pass
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
    cpdef run(self):
        cdef unsigned int i
        cdef double time1, time2
        print("test1")
        #self.func1()
        time1 = time()
        #for i in range(100000000):
        #    self.func2(0x40)
        self.func3()
        time2 = time()-time1
        print("test3: {0:f}".format(time2))
        print("test2")



