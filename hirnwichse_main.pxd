
from misc cimport Misc
from mm cimport Mm
from X86Platform cimport Platform
from cpu cimport Cpu


cdef class Hirnwichse:
    cpdef object parser, cmdArgs
    cdef public Misc misc
    cdef public Mm mm
    cdef public Platform platform
    cdef public Cpu cpu
    cdef public unsigned char quitEmu, debugEnabled, exitIfCpuHalted, noUI, exitOnTripleFault, fdaType, fdbType, \
                              debugHalt, bootFrom, debugEnabledTest
    cdef public unsigned int memSize
    cdef public bytes romPath, biosFilename, vgaBiosFilename, fdaFilename, fdbFilename, hdaFilename, hdbFilename, \
                      cdromFilename
    cpdef parseArgs(self)
    cpdef quitFunc(self)
    cpdef reset(self, unsigned char resetHardware)
    cpdef run(self)



