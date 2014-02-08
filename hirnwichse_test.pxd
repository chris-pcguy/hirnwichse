
from mm cimport Mm
from pic cimport Pic, SetINTR
from isadma cimport IsaDma, SetHRQ
from pythonBios cimport PythonBios
from hirnwichse_main cimport Hirnwichse

cdef class HirnwichseTest(Hirnwichse):
    cdef runThreadFunc(self)
    cdef test1(self)


