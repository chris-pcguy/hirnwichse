
DEF COMP_DEBUG = 1

cdef unsigned char OP_SIZE_BYTE  = 1
cdef unsigned char OP_SIZE_WORD  = 2
cdef unsigned char OP_SIZE_DWORD = 4
cdef unsigned char OP_SIZE_QWORD = 8

DEF BITMASK_BYTE_CONST = 0xff
cdef unsigned char BITMASK_BYTE = 0xff
cdef unsigned short BITMASK_WORD = 0xffff
cdef unsigned int BITMASK_DWORD = 0xffffffff
cdef unsigned long int BITMASK_QWORD = 0xffffffffffffffff



cdef unsigned char CMOS_CURRENT_SECOND    = 0x00
cdef unsigned char CMOS_ALARM_SECOND      = 0x01
cdef unsigned char CMOS_CURRENT_MINUTE    = 0x02
cdef unsigned char CMOS_ALARM_MINUTE      = 0x03
cdef unsigned char CMOS_CURRENT_HOUR      = 0x04
cdef unsigned char CMOS_ALARM_HOUR        = 0x05
cdef unsigned char CMOS_DAY_OF_WEEK       = 0x06
cdef unsigned char CMOS_DAY_OF_MONTH      = 0x07
cdef unsigned char CMOS_MONTH             = 0x08
cdef unsigned char CMOS_YEAR_NO_CENTURY   = 0x09 # year without century: e.g.  00 - 99
cdef unsigned char CMOS_STATUS_REGISTER_A = 0x0a
cdef unsigned char CMOS_STATUS_REGISTER_B = 0x0b
cdef unsigned char CMOS_STATUS_REGISTER_C = 0x0c
cdef unsigned char CMOS_STATUS_REGISTER_D = 0x0d
cdef unsigned char CMOS_SHUTDOWN_STATUS   = 0x0f
cdef unsigned char CMOS_FLOPPY_DRIVE_TYPE = 0x10
cdef unsigned char CMOS_HDD_DRIVE_TYPE    = 0x12
cdef unsigned char CMOS_HD0_EXTENDED_DRIVE_TYPE = 0x19
cdef unsigned char CMOS_HD1_EXTENDED_DRIVE_TYPE = 0x1a
cdef unsigned char CMOS_HD0_CYLINDERS = 0x1b
cdef unsigned char CMOS_HD1_CYLINDERS = 0x24
cdef unsigned char CMOS_HD0_WRITE_PRECOMP = 0x1e
cdef unsigned char CMOS_HD1_WRITE_PRECOMP = 0x27
cdef unsigned char CMOS_HD0_LANDING_ZONE = 0x21
cdef unsigned char CMOS_HD1_LANDING_ZONE = 0x2a
cdef unsigned char CMOS_HD0_HEADS = 0x1d
cdef unsigned char CMOS_HD1_HEADS = 0x26
cdef unsigned char CMOS_HD0_SPT = 0x23
cdef unsigned char CMOS_HD1_SPT = 0x2c
cdef unsigned char CMOS_HD0_CONTROL_BYTE  = 0x20
cdef unsigned char CMOS_HD1_CONTROL_BYTE  = 0x29
cdef unsigned char CMOS_EQUIPMENT_BYTE    = 0x14
cdef unsigned char CMOS_BASE_MEMORY_L     = 0x15
cdef unsigned char CMOS_BASE_MEMORY_H     = 0x16
cdef unsigned char CMOS_EXT_MEMORY_L      = 0x17
cdef unsigned char CMOS_EXT_MEMORY_H      = 0x18
cdef unsigned char CMOS_EXT_BIOS_CFG      = 0x2d
cdef unsigned char CMOS_CHECKSUM_H        = 0x2e
cdef unsigned char CMOS_CHECKSUM_L        = 0x2f
cdef unsigned char CMOS_EXT_MEMORY_L2     = 0x30
cdef unsigned char CMOS_EXT_MEMORY_H2     = 0x31
cdef unsigned char CMOS_CENTURY           = 0x32
cdef unsigned char CMOS_EXT_MEMORY2_L     = 0x34
cdef unsigned char CMOS_EXT_MEMORY2_H     = 0x35
cdef unsigned char CMOS_BOOT_FROM_3       = 0x38
cdef unsigned char CMOS_BOOT_FROM_1_2     = 0x3d
cdef unsigned char CMOS_ATA_0_1_TRANSLATION = 0x39
cdef unsigned char CMOS_ATA_2_3_TRANSLATION = 0x3a
cdef unsigned char CMOS_RTC_IRQ          = 0x8

cdef unsigned char IRQ_SECOND_PIC = 0x2

cdef unsigned char ATA_TRANSLATE_NONE  = 0
cdef unsigned char ATA_TRANSLATE_LBA   = 1
cdef unsigned char ATA_TRANSLATE_LARGE = 2
cdef unsigned char ATA_TRANSLATE_RECHS = 3

cdef unsigned char ATA_BUSMASTER_CMD_READ_TO_MEM = 0x8

cdef unsigned char CMOS_STATUSB_24HOUR = 0x02
cdef unsigned char CMOS_STATUSB_BIN    = 0x04

cdef unsigned char FLOPPY_DISK_TYPE_NONE  = 0
cdef unsigned char FLOPPY_DISK_TYPE_360K  = 1
cdef unsigned char FLOPPY_DISK_TYPE_1_2M  = 2
cdef unsigned char FLOPPY_DISK_TYPE_720K  = 3
cdef unsigned char FLOPPY_DISK_TYPE_1_44M = 4
cdef unsigned char FLOPPY_DISK_TYPE_2_88M = 5
cdef unsigned char FLOPPY_DISK_TYPE_160K  = 6
cdef unsigned char FLOPPY_DISK_TYPE_180K  = 7
cdef unsigned char FLOPPY_DISK_TYPE_320K  = 8

cdef unsigned char BOOT_FROM_NONE = 0
cdef unsigned char BOOT_FROM_FD = 1
cdef unsigned char BOOT_FROM_HD = 2
cdef unsigned char BOOT_FROM_CD = 3

cdef unsigned int SIZE_1MB_MASK = 0xfffff

cdef unsigned int LAST_MEMAREA_BASE_ADDR = 0xfff00000

cdef unsigned int SIZE_360K = 368640
cdef unsigned int SIZE_720K = 737280
cdef unsigned int SIZE_1_2M = 1228800
cdef unsigned int SIZE_1_44M = 1474560
cdef unsigned int SIZE_2_88M = 2867200

cdef unsigned int SIZE_4KB  = 0x1000
cdef unsigned int SIZE_64KB  = 0x10000
cdef unsigned int SIZE_128KB = 0x20000
cdef unsigned int SIZE_256KB = 0x40000
cdef unsigned int SIZE_512KB = 0x80000
cdef unsigned int SIZE_1MB   = 0x100000
cdef unsigned int SIZE_2MB   = 0x200000
cdef unsigned int SIZE_4MB   = 0x400000
cdef unsigned int SIZE_8MB   = 0x800000
cdef unsigned int SIZE_16MB  = 0x1000000
cdef unsigned int SIZE_32MB  = 0x2000000
cdef unsigned int SIZE_64MB  = 0x4000000
cdef unsigned int SIZE_128MB = 0x8000000
cdef unsigned int SIZE_256MB = 0x10000000
cdef unsigned long int SIZE_4GB = 0x100000000

cdef tuple ROM_SIZES = (SIZE_64KB, SIZE_128KB, SIZE_256KB, SIZE_512KB, SIZE_1MB, SIZE_2MB, SIZE_4MB,
             SIZE_8MB, SIZE_16MB, SIZE_32MB, SIZE_64MB, SIZE_128MB, SIZE_256MB)


cdef unsigned int VGA_MEMAREA_ADDR = 0xa0000
cdef unsigned short VGA_SEQ_INDEX_ADDR = 0x3c4
cdef unsigned short VGA_SEQ_DATA_ADDR  = 0x3c5
cdef unsigned short VGA_SEQ_AREA_SIZE = 0x5
cdef unsigned short VGA_CRT_AREA_SIZE = 0x19
cdef unsigned short VGA_GDC_AREA_SIZE = 0x9
cdef unsigned short VGA_DAC_AREA_SIZE = 0x300
cdef unsigned short VGA_ATTRCTRLREG_AREA_SIZE = 0x15
cdef unsigned char VGA_CRT_OFREG_LC8 = 0x10
cdef unsigned char VGA_CRT_PROTECT_REGISTERS = 0x80
cdef unsigned char VGA_CRT_OVERFLOW_REG_INDEX = 0x7
cdef unsigned char VGA_CRT_MAX_SCANLINE_REG_INDEX = 0x9
cdef unsigned char VGA_CRT_VDE_REG_INDEX = 0x12
cdef unsigned char VGA_CRT_UNDERLINE_LOCATION_INDEX = 0x14
cdef unsigned char VGA_CRT_UNDERLINE_LOCATION_DW = 0x40
cdef unsigned char VGA_CRT_OFFSET_INDEX = 0x13
cdef unsigned char VGA_CRT_MODE_CTRL_INDEX = 0x17
cdef unsigned char VGA_CRT_MODE_CTRL_WORD_BYTE = 0x40
cdef unsigned char VGA_GDC_RESET_REG_INDEX = 0x00
cdef unsigned char VGA_GDC_ENABLE_RESET_REG_INDEX = 0x01
cdef unsigned char VGA_GDC_COLOR_COMPARE_INDEX = 0x02
cdef unsigned char VGA_GDC_DATA_ROTATE_INDEX = 0x03
cdef unsigned char VGA_GDC_READ_MAP_SEL_INDEX = 0x04
cdef unsigned char VGA_GDC_MODE_REG_INDEX = 0x05
cdef unsigned char VGA_GDC_MISC_GREG_INDEX = 0x06
cdef unsigned char VGA_GDC_COLOR_DONT_CARE_INDEX = 0x07
cdef unsigned char VGA_GDC_BIT_MASK_INDEX = 0x08
cdef unsigned char VGA_GDC_MEMBASE_MASK       = 0x03
cdef unsigned char VGA_GDC_MEMBASE_A0000_128K = 0x00
cdef unsigned char VGA_GDC_MEMBASE_A0000_64K  = 0x01
cdef unsigned char VGA_GDC_MEMBASE_B0000_32K  = 0x02
cdef unsigned char VGA_GDC_MEMBASE_B8000_32K  = 0x03
cdef unsigned char VGA_GDC_CHAIN_ODD_EVEN = 0x2
cdef unsigned char VGA_GDC_ALPHA_DIS = 0x1
cdef unsigned char VGA_ATTRCTRLREG_PALETTE_ENABLED = 0x20
cdef unsigned char VGA_ATTRCTRLREG_CONTROL_REG_INDEX = 0x10
cdef unsigned char VGA_ATTRCTRLREG_CONTROL_REG_PALETTE54 = 0x80
cdef unsigned char VGA_ATTRCTRLREG_CONTROL_REG_8BIT = 0x40
cdef unsigned char VGA_ATTRCTRLREG_CONTROL_REG_BLINK = 0x8
cdef unsigned char VGA_ATTRCTRLREG_CONTROL_REG_LGE = 0x4
cdef unsigned char VGA_ATTRCTRLREG_CONTROL_REG_GRAPHICAL_MODE = 0x1
cdef unsigned char VGA_ATTRCTRLREG_COLOR_PLANE_ENABLE_REG_INDEX = 0x12
cdef unsigned char VGA_ATTRCTRLREG_COLOR_SELECT_REG_INDEX = 0x14
cdef unsigned char VGA_SEQ_CLOCKING_MODE_REG_INDEX = 0x01
cdef unsigned char VGA_SEQ_PLANE_SEL_INDEX = 0x02
cdef unsigned char VGA_SEQ_CHARMAP_SEL_INDEX = 0x03
cdef unsigned char VGA_SEQ_MEM_MODE_INDEX = 0x04
cdef unsigned char VGA_SEQ_MODE_9BIT = 0x01
cdef unsigned char VGA_EXTREG_PROCESS_RAM = 0x2
cdef unsigned char VGA_EXTREG_COLOR_MODE = 0x1
#cdef unsigned short VGA_FONTAREA_SIZE = 0x4000
DEF VGA_FONTAREA_SIZE = 0x4000
cdef unsigned char VGA_FONTAREA_CHAR_HEIGHT = 32
cdef unsigned int VGA_PLANE_SIZE = 65536 # 64K


cdef unsigned char PPCB_T2_GATE = 0x01
cdef unsigned char PPCB_T2_SPKR   = 0x02
cdef unsigned char PPCB_T2_OUT  = 0x20
cdef unsigned char PORT_61H_LOWER_TIMER_IRQ = 0x80

cdef unsigned short PCI_FUNCTION_CONFIG_SIZE = 256

cdef unsigned char PCI_BUS_SHIFT = 16
cdef unsigned char PCI_DEVICE_SHIFT = 11
cdef unsigned char PCI_FUNCTION_SHIFT = 8

cdef unsigned char PCI_VENDOR_ID = 0x00
cdef unsigned char PCI_DEVICE_ID = 0x02
cdef unsigned char PCI_COMMAND = 0x04
cdef unsigned char PCI_STATUS = 0x06
cdef unsigned char PCI_PROG_IF = 0x09
cdef unsigned char PCI_DEVICE_CLASS = 0x0a
cdef unsigned char PCI_HEADER_TYPE = 0x0e
cdef unsigned char PCI_BIST = 0xf
cdef unsigned char PCI_BASE_ADDRESS_0 = 0x10
cdef unsigned char PCI_BASE_ADDRESS_1 = 0x14
cdef unsigned char PCI_BASE_ADDRESS_2 = 0x18
cdef unsigned char PCI_BASE_ADDRESS_3 = 0x1c
cdef unsigned char PCI_BASE_ADDRESS_4 = 0x20
cdef unsigned char PCI_BASE_ADDRESS_5 = 0x24
cdef unsigned char PCI_ROM_ADDRESS = 0x30
cdef unsigned char PCI_CAPABILITIES_POINTER = 0x34
cdef unsigned char PCI_INTERRUPT_LINE = 0x3c
cdef unsigned char PCI_INTERRUPT_PIN = 0x3d

cdef unsigned char PCI_BRIDGE_IO_BASE_LOW = 0x1c
cdef unsigned char PCI_BRIDGE_IO_LIMIT_LOW = 0x1d
cdef unsigned char PCI_BRIDGE_MEM_BASE = 0x20
cdef unsigned char PCI_BRIDGE_MEM_LIMIT = 0x22
cdef unsigned char PCI_BRIDGE_PREF_MEM_BASE_LOW = 0x24
cdef unsigned char PCI_BRIDGE_PREF_MEM_LIMIT_LOW = 0x26
cdef unsigned char PCI_BRIDGE_PREF_MEM_BASE_HIGH = 0x28
cdef unsigned char PCI_BRIDGE_PREF_MEM_LIMIT_HIGH = 0x2c
cdef unsigned char PCI_BRIDGE_IO_BASE_HIGH = 0x30
cdef unsigned char PCI_BRIDGE_IO_LIMIT_HIGH = 0x32
cdef unsigned char PCI_BRIDGE_ROM_ADDRESS = 0x38


cdef unsigned char PCI_PRIMARY_BUS = 0x18
cdef unsigned char PCI_SECONDARY_BUS = 0x19
cdef unsigned char PCI_SUBORDINATE_BUS = 0x1a

cdef unsigned short PCI_CLASS_PATA        = 0x0101
cdef unsigned short PCI_CLASS_VGA         = 0x0300
cdef unsigned short PCI_CLASS_BRIDGE_HOST = 0x0600
cdef unsigned short PCI_CLASS_BRIDGE_PCI  = 0x0604
cdef unsigned short PCI_VENDOR_ID_INTEL   = 0x8086
cdef unsigned short PCI_DEVICE_ID_INTEL_440FX = 0x1237

cdef unsigned char PCI_HEADER_TYPE_STANDARD = 0
cdef unsigned char PCI_HEADER_TYPE_BRIDGE = 1
cdef unsigned char PCI_RESET_VALUE = 0x02


cdef unsigned char PCI_BAR0_ENABLED_MASK = 0x1
cdef unsigned char PCI_BAR1_ENABLED_MASK = 0x2
cdef unsigned char PCI_BAR2_ENABLED_MASK = 0x4
cdef unsigned char PCI_BAR3_ENABLED_MASK = 0x8
cdef unsigned char PCI_BAR4_ENABLED_MASK = 0x10
cdef unsigned char PCI_BAR5_ENABLED_MASK = 0x20

cdef unsigned int PCI_MEM_BASE = 0xc0000000
cdef unsigned int PCI_MEM_BASE_PLUS_LIMIT = 0xc0100000

cdef unsigned int VGA_ROM_BASE = 0xc0000


DEF DMA_EXT_PAGE_REG_PORTS = (0x80, 0x84, 0x85, 0x86, 0x88, 0x8c, 0x8d, 0x8e)
DEF PCI_CONTROLLER_PORTS = (0x4d0, 0x4d1, 0xcf8, 0xcf9, 0xcfc, 0xcfd, 0xcfe, 0xcff)
DEF ATA1_PORTS = (0x1f0, 0x1f1, 0x1f2, 0x1f3, 0x1f4, 0x1f5, 0x1f6, 0x1f7, 0x3f6)
DEF ATA2_PORTS = (0x170, 0x171, 0x172, 0x173, 0x174, 0x175, 0x176, 0x177, 0x376)
DEF ATA3_PORTS = (0x1e8, 0x1e9, 0x1ea, 0x1eb, 0x1ec, 0x1ed, 0x1ee, 0x1ef, 0x3e6, 0x3e7, 0x3ee)
DEF ATA4_PORTS = (0x168, 0x169, 0x16a, 0x16b, 0x16c, 0x16d, 0x16e, 0x16f, 0x366, 0x367, 0x36e)
DEF FDC_FIRST_READ_PORTS = (0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f7)
DEF FDC_SECOND_READ_PORTS = (0x372, 0x373, 0x374, 0x375, 0x377)
DEF FDC_FIRST_WRITE_PORTS = (0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f7)
DEF FDC_SECOND_WRITE_PORTS = (0x372, 0x373, 0x374, 0x375, 0x377)

DEF VGA_READ_PORTS = (0x1ce, 0x1cf, 0x3b4, 0x3b5, 0x3ba, 0x3c0, 0x3c1, 0x3c2, 0x3c4, 0x3c5, 0x3cc, 0x3c7, 0x3c8, 0x3c9, 0x3ca, 0x3ce, 0x3cf, 0x3d4, 0x3d5, 0x3da)
DEF VGA_WRITE_PORTS = (0x1ce, 0x1cf, 0x3b4, 0x3b5, 0x3ba, 0x3c0, 0x3c2, 0x3c4, 0x3c5, 0x3c6, 0x3c7, 0x3c8, 0x3c9, 0x3ca, 0x3ce, 0x3cf, 0x3d4, 0x3d5, 0x3da, 0x400, 0x401, 0x402, 0x403, 0x500, 0x504, 0x8900, 0xb004)

DEF SERIAL_PORTS = (0x3f8, 0x3f9, 0x3fa, 0x3fb, 0x3fc, 0x3fd, 0x3fe, 0x3ff, 0x2f8, 0x2f9, 0x2fa, 0x2fb, 0x2fc, 0x2fd, 0x2fe, 0x2ff)
DEF SERIAL1_PORTS = (0x3f8, 0x3f9, 0x3fa, 0x3fb, 0x3fc, 0x3fd, 0x3fe, 0x3ff)
DEF SERIAL2_PORTS = (0x2f8, 0x2f9, 0x2fa, 0x2fb, 0x2fc, 0x2fd, 0x2fe, 0x2ff)


cdef unsigned long int BITMASKS_80[9]
BITMASKS_80 = (0, 0x80, 0x8000, 0, 0x80000000, 0, 0, 0, 0x8000000000000000)
cdef unsigned long int BITMASKS_FF[9]
BITMASKS_FF = (0, BITMASK_BYTE, BITMASK_WORD, 0, BITMASK_DWORD, 0, 0, 0, BITMASK_QWORD)

