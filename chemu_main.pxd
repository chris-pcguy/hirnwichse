
cdef class ChEmu:
    cpdef public object misc, mm, platform, cpu
    cpdef object parser, cmdArgs
    cdef unsigned char debugEnabled
    cdef public unsigned char quitEmu, exitIfCpuHalted, exitCode, noUI, exitOnTripleFault, forceFloppyDiskType
    cdef public unsigned long long memSize
    cdef public bytes romPath, biosFilename, vgaBiosFilename, fdaFilename, fdbFilename
    cpdef parseArgs(self)
    cpdef quitFunc(self)
    cpdef testCase(self)
    #cpdef runCDEF(self)
    cpdef run(self)



