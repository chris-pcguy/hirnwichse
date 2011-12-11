
cimport misc, mm, X86Platform, cpu


cdef class ChEmu:
    cpdef public misc.Misc misc
    cpdef public mm.Mm mm
    cpdef public X86Platform.Platform platform
    ##cpdef public cpu.Cpu cpu
    cpdef public object cpu
    ##cpdef public object misc, mm, platform, cpu
    cpdef object parser, cmdArgs
    cdef unsigned char debugEnabled
    cdef public unsigned char quitEmu, exitIfCpuHalted, exitCode, noUI, exitOnTripleFault, forceFloppyDiskType
    cdef public unsigned long long memSize
    cdef public bytes romPath, biosFilename, vgaBiosFilename, fdaFilename, fdbFilename
    cpdef parseArgs(self)
    cpdef quitFunc(self)
    cpdef run(self)



