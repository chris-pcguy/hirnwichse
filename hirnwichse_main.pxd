
from libc.stdint cimport *

from misc cimport Misc
from mm cimport Mm
from X86Platform cimport Platform
from cpu cimport Cpu


cdef class Hirnwichse:
    cdef object parser, cmdArgs #, executor
    cdef Misc misc
    cdef Mm mm
    cdef Platform platform
    cdef Cpu cpu
    cdef uint8_t quitEmu, debugEnabled, exitIfCpuHalted, noUI, exitOnTripleFault, fdaType, fdbType, debugHalt, bootFrom, debugEnabledTest
    cdef uint32_t memSize
    cdef bytes romPath, biosFilename, vgaBiosFilename, fdaFilename, fdbFilename, hdaFilename, hdbFilename, cdrom1Filename, cdrom2Filename, serial1Filename, serial2Filename, serial3Filename, serial4Filename
    cdef void parseArgs(self)
    cdef void quitFunc(self)
    cdef void exitError(self, char *msg, msgArgs=*)
    cdef void debug(self, char *msg, msgArgs=*)
    cdef void notice(self, char *msg, msgArgs=*)
    cdef void reset(self, uint8_t resetHardware)
    cpdef void run(self, uint8_t infiniteCycles)



