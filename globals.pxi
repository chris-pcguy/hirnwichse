
from libc.stdint cimport *

DEF COMP_DEBUG = 0

cdef uint8_t OP_SIZE_BYTE  = 1
cdef uint8_t OP_SIZE_WORD  = 2
cdef uint8_t OP_SIZE_DWORD = 4
cdef uint8_t OP_SIZE_QWORD = 8

DEF BITMASK_BYTE_CONST = 0xff
cdef uint8_t BITMASK_BYTE = 0xff
cdef uint16_t BITMASK_WORD = 0xffff
cdef uint32_t BITMASK_DWORD = 0xffffffff
cdef uint64_t BITMASK_QWORD = 0xffffffffffffffff



cdef uint8_t CMOS_CURRENT_SECOND    = 0x00
cdef uint8_t CMOS_ALARM_SECOND      = 0x01
cdef uint8_t CMOS_CURRENT_MINUTE    = 0x02
cdef uint8_t CMOS_ALARM_MINUTE      = 0x03
cdef uint8_t CMOS_CURRENT_HOUR      = 0x04
cdef uint8_t CMOS_ALARM_HOUR        = 0x05
cdef uint8_t CMOS_DAY_OF_WEEK       = 0x06
cdef uint8_t CMOS_DAY_OF_MONTH      = 0x07
cdef uint8_t CMOS_MONTH             = 0x08
cdef uint8_t CMOS_YEAR_NO_CENTURY   = 0x09 # year without century: e.g.  00 - 99
cdef uint8_t CMOS_STATUS_REGISTER_A = 0x0a
cdef uint8_t CMOS_STATUS_REGISTER_B = 0x0b
cdef uint8_t CMOS_STATUS_REGISTER_C = 0x0c
cdef uint8_t CMOS_STATUS_REGISTER_D = 0x0d
cdef uint8_t CMOS_SHUTDOWN_STATUS   = 0x0f
cdef uint8_t CMOS_FLOPPY_DRIVE_TYPE = 0x10
cdef uint8_t CMOS_HDD_DRIVE_TYPE    = 0x12
cdef uint8_t CMOS_HD0_EXTENDED_DRIVE_TYPE = 0x19
cdef uint8_t CMOS_HD1_EXTENDED_DRIVE_TYPE = 0x1a
cdef uint8_t CMOS_HD0_CYLINDERS = 0x1b
cdef uint8_t CMOS_HD1_CYLINDERS = 0x24
cdef uint8_t CMOS_HD0_WRITE_PRECOMP = 0x1e
cdef uint8_t CMOS_HD1_WRITE_PRECOMP = 0x27
cdef uint8_t CMOS_HD0_LANDING_ZONE = 0x21
cdef uint8_t CMOS_HD1_LANDING_ZONE = 0x2a
cdef uint8_t CMOS_HD0_HEADS = 0x1d
cdef uint8_t CMOS_HD1_HEADS = 0x26
cdef uint8_t CMOS_HD0_SPT = 0x23
cdef uint8_t CMOS_HD1_SPT = 0x2c
cdef uint8_t CMOS_HD0_CONTROL_BYTE  = 0x20
cdef uint8_t CMOS_HD1_CONTROL_BYTE  = 0x29
cdef uint8_t CMOS_EQUIPMENT_BYTE    = 0x14
cdef uint8_t CMOS_BASE_MEMORY_L     = 0x15
cdef uint8_t CMOS_BASE_MEMORY_H     = 0x16
cdef uint8_t CMOS_EXT_MEMORY_L      = 0x17
cdef uint8_t CMOS_EXT_MEMORY_H      = 0x18
cdef uint8_t CMOS_EXT_BIOS_CFG      = 0x2d
cdef uint8_t CMOS_CHECKSUM_H        = 0x2e
cdef uint8_t CMOS_CHECKSUM_L        = 0x2f
cdef uint8_t CMOS_EXT_MEMORY_L2     = 0x30
cdef uint8_t CMOS_EXT_MEMORY_H2     = 0x31
cdef uint8_t CMOS_CENTURY           = 0x32
cdef uint8_t CMOS_EXT_MEMORY2_L     = 0x34
cdef uint8_t CMOS_EXT_MEMORY2_H     = 0x35
cdef uint8_t CMOS_BOOT_FROM_3       = 0x38
cdef uint8_t CMOS_BOOT_FROM_1_2     = 0x3d
cdef uint8_t CMOS_ATA_0_1_TRANSLATION = 0x39
cdef uint8_t CMOS_ATA_2_3_TRANSLATION = 0x3a
cdef uint8_t CMOS_RTC_IRQ          = 0x8

cdef uint8_t IRQ_SECOND_PIC = 0x2

cdef uint8_t ATA_TRANSLATE_NONE  = 0
cdef uint8_t ATA_TRANSLATE_LBA   = 1
cdef uint8_t ATA_TRANSLATE_LARGE = 2
cdef uint8_t ATA_TRANSLATE_RECHS = 3

cdef uint8_t ATA_BUSMASTER_CMD_READ_TO_MEM = 0x8

cdef uint8_t CMOS_STATUSB_24HOUR = 0x02
cdef uint8_t CMOS_STATUSB_BIN    = 0x04

cdef uint8_t FLOPPY_DISK_TYPE_NONE  = 0
cdef uint8_t FLOPPY_DISK_TYPE_360K  = 1
cdef uint8_t FLOPPY_DISK_TYPE_1_2M  = 2
cdef uint8_t FLOPPY_DISK_TYPE_720K  = 3
cdef uint8_t FLOPPY_DISK_TYPE_1_44M = 4
cdef uint8_t FLOPPY_DISK_TYPE_2_88M = 5
cdef uint8_t FLOPPY_DISK_TYPE_160K  = 6
cdef uint8_t FLOPPY_DISK_TYPE_180K  = 7
cdef uint8_t FLOPPY_DISK_TYPE_320K  = 8

cdef uint8_t BOOT_FROM_NONE = 0
cdef uint8_t BOOT_FROM_FD = 1
cdef uint8_t BOOT_FROM_HD = 2
cdef uint8_t BOOT_FROM_CD = 3

cdef uint32_t SIZE_1MB_MASK = 0xfffff

cdef uint32_t LAST_MEMAREA_BASE_ADDR = 0xfff00000

cdef uint32_t SIZE_360K = 368640
cdef uint32_t SIZE_720K = 737280
cdef uint32_t SIZE_1_2M = 1228800
cdef uint32_t SIZE_1_44M = 1474560
cdef uint32_t SIZE_2_88M = 2867200

cdef uint32_t SIZE_4KB  = 0x1000
cdef uint32_t SIZE_64KB  = 0x10000
cdef uint32_t SIZE_128KB = 0x20000
cdef uint32_t SIZE_256KB = 0x40000
cdef uint32_t SIZE_512KB = 0x80000
cdef uint32_t SIZE_1MB   = 0x100000
cdef uint32_t SIZE_2MB   = 0x200000
cdef uint32_t SIZE_4MB   = 0x400000
cdef uint32_t SIZE_8MB   = 0x800000
cdef uint32_t SIZE_16MB  = 0x1000000
cdef uint32_t SIZE_32MB  = 0x2000000
cdef uint32_t SIZE_64MB  = 0x4000000
cdef uint32_t SIZE_128MB = 0x8000000
cdef uint32_t SIZE_256MB = 0x10000000
cdef uint64_t SIZE_4GB = 0x100000000

cdef tuple ROM_SIZES = (SIZE_64KB, SIZE_128KB, SIZE_256KB, SIZE_512KB, SIZE_1MB, SIZE_2MB, SIZE_4MB,
             SIZE_8MB, SIZE_16MB, SIZE_32MB, SIZE_64MB, SIZE_128MB, SIZE_256MB)


cdef uint32_t VGA_MEMAREA_ADDR = 0xa0000
cdef uint16_t VGA_SEQ_INDEX_ADDR = 0x3c4
cdef uint16_t VGA_SEQ_DATA_ADDR  = 0x3c5
cdef uint16_t VGA_SEQ_AREA_SIZE = 0x5
cdef uint16_t VGA_CRT_AREA_SIZE = 0x19
cdef uint16_t VGA_GDC_AREA_SIZE = 0x9
cdef uint16_t VGA_DAC_AREA_SIZE = 0x300
cdef uint16_t VGA_ATTRCTRLREG_AREA_SIZE = 0x15
cdef uint8_t VGA_CRT_OFREG_LC8 = 0x10
cdef uint8_t VGA_CRT_PROTECT_REGISTERS = 0x80
cdef uint8_t VGA_CRT_OVERFLOW_REG_INDEX = 0x7
cdef uint8_t VGA_CRT_MAX_SCANLINE_REG_INDEX = 0x9
cdef uint8_t VGA_CRT_VDE_REG_INDEX = 0x12
cdef uint8_t VGA_CRT_UNDERLINE_LOCATION_INDEX = 0x14
cdef uint8_t VGA_CRT_UNDERLINE_LOCATION_DW = 0x40
cdef uint8_t VGA_CRT_OFFSET_INDEX = 0x13
cdef uint8_t VGA_CRT_MODE_CTRL_INDEX = 0x17
cdef uint8_t VGA_CRT_MODE_CTRL_WORD_BYTE = 0x40
cdef uint8_t VGA_GDC_RESET_REG_INDEX = 0x00
cdef uint8_t VGA_GDC_ENABLE_RESET_REG_INDEX = 0x01
cdef uint8_t VGA_GDC_COLOR_COMPARE_INDEX = 0x02
cdef uint8_t VGA_GDC_DATA_ROTATE_INDEX = 0x03
cdef uint8_t VGA_GDC_READ_MAP_SEL_INDEX = 0x04
cdef uint8_t VGA_GDC_MODE_REG_INDEX = 0x05
cdef uint8_t VGA_GDC_MISC_GREG_INDEX = 0x06
cdef uint8_t VGA_GDC_COLOR_DONT_CARE_INDEX = 0x07
cdef uint8_t VGA_GDC_BIT_MASK_INDEX = 0x08
cdef uint8_t VGA_GDC_MEMBASE_MASK       = 0x03
cdef uint8_t VGA_GDC_MEMBASE_A0000_128K = 0x00
cdef uint8_t VGA_GDC_MEMBASE_A0000_64K  = 0x01
cdef uint8_t VGA_GDC_MEMBASE_B0000_32K  = 0x02
cdef uint8_t VGA_GDC_MEMBASE_B8000_32K  = 0x03
cdef uint8_t VGA_GDC_CHAIN_ODD_EVEN = 0x2
cdef uint8_t VGA_GDC_ALPHA_DIS = 0x1
cdef uint8_t VGA_ATTRCTRLREG_PALETTE_ENABLED = 0x20
cdef uint8_t VGA_ATTRCTRLREG_CONTROL_REG_INDEX = 0x10
cdef uint8_t VGA_ATTRCTRLREG_CONTROL_REG_PALETTE54 = 0x80
cdef uint8_t VGA_ATTRCTRLREG_CONTROL_REG_8BIT = 0x40
cdef uint8_t VGA_ATTRCTRLREG_CONTROL_REG_BLINK = 0x8
cdef uint8_t VGA_ATTRCTRLREG_CONTROL_REG_LGE = 0x4
cdef uint8_t VGA_ATTRCTRLREG_CONTROL_REG_GRAPHICAL_MODE = 0x1
cdef uint8_t VGA_ATTRCTRLREG_COLOR_PLANE_ENABLE_REG_INDEX = 0x12
cdef uint8_t VGA_ATTRCTRLREG_COLOR_SELECT_REG_INDEX = 0x14
cdef uint8_t VGA_SEQ_CLOCKING_MODE_REG_INDEX = 0x01
cdef uint8_t VGA_SEQ_PLANE_SEL_INDEX = 0x02
cdef uint8_t VGA_SEQ_CHARMAP_SEL_INDEX = 0x03
cdef uint8_t VGA_SEQ_MEM_MODE_INDEX = 0x04
cdef uint8_t VGA_SEQ_MODE_9BIT = 0x01
cdef uint8_t VGA_EXTREG_PROCESS_RAM = 0x2
cdef uint8_t VGA_EXTREG_COLOR_MODE = 0x1
#cdef uint16_t VGA_FONTAREA_SIZE = 0x4000
DEF VGA_FONTAREA_SIZE = 0x4000
cdef uint8_t VGA_FONTAREA_CHAR_HEIGHT = 32
cdef uint32_t VGA_PLANE_SIZE = 65536 # 64K


cdef uint8_t PPCB_T2_GATE = 0x01
cdef uint8_t PPCB_T2_SPKR   = 0x02
cdef uint8_t PPCB_T2_OUT  = 0x20
cdef uint8_t PORT_61H_LOWER_TIMER_IRQ = 0x80

cdef uint16_t PCI_FUNCTION_CONFIG_SIZE = 256

cdef uint8_t PCI_BUS_SHIFT = 16
cdef uint8_t PCI_DEVICE_SHIFT = 11
cdef uint8_t PCI_FUNCTION_SHIFT = 8

cdef uint8_t PCI_VENDOR_ID = 0x00
cdef uint8_t PCI_DEVICE_ID = 0x02
cdef uint8_t PCI_COMMAND = 0x04
cdef uint8_t PCI_STATUS = 0x06
cdef uint8_t PCI_PROG_IF = 0x09
cdef uint8_t PCI_DEVICE_CLASS = 0x0a
cdef uint8_t PCI_HEADER_TYPE = 0x0e
cdef uint8_t PCI_BIST = 0xf
cdef uint8_t PCI_BASE_ADDRESS_0 = 0x10
cdef uint8_t PCI_BASE_ADDRESS_1 = 0x14
cdef uint8_t PCI_BASE_ADDRESS_2 = 0x18
cdef uint8_t PCI_BASE_ADDRESS_3 = 0x1c
cdef uint8_t PCI_BASE_ADDRESS_4 = 0x20
cdef uint8_t PCI_BASE_ADDRESS_5 = 0x24
cdef uint8_t PCI_ROM_ADDRESS = 0x30
cdef uint8_t PCI_CAPABILITIES_POINTER = 0x34
cdef uint8_t PCI_INTERRUPT_LINE = 0x3c
cdef uint8_t PCI_INTERRUPT_PIN = 0x3d

cdef uint8_t PCI_BRIDGE_IO_BASE_LOW = 0x1c
cdef uint8_t PCI_BRIDGE_IO_LIMIT_LOW = 0x1d
cdef uint8_t PCI_BRIDGE_MEM_BASE = 0x20
cdef uint8_t PCI_BRIDGE_MEM_LIMIT = 0x22
cdef uint8_t PCI_BRIDGE_PREF_MEM_BASE_LOW = 0x24
cdef uint8_t PCI_BRIDGE_PREF_MEM_LIMIT_LOW = 0x26
cdef uint8_t PCI_BRIDGE_PREF_MEM_BASE_HIGH = 0x28
cdef uint8_t PCI_BRIDGE_PREF_MEM_LIMIT_HIGH = 0x2c
cdef uint8_t PCI_BRIDGE_IO_BASE_HIGH = 0x30
cdef uint8_t PCI_BRIDGE_IO_LIMIT_HIGH = 0x32
cdef uint8_t PCI_BRIDGE_ROM_ADDRESS = 0x38


cdef uint8_t PCI_PRIMARY_BUS = 0x18
cdef uint8_t PCI_SECONDARY_BUS = 0x19
cdef uint8_t PCI_SUBORDINATE_BUS = 0x1a

cdef uint16_t PCI_CLASS_PATA        = 0x0101
cdef uint16_t PCI_CLASS_VGA         = 0x0300
cdef uint16_t PCI_CLASS_BRIDGE_HOST = 0x0600
cdef uint16_t PCI_CLASS_BRIDGE_PCI  = 0x0604
cdef uint16_t PCI_VENDOR_ID_INTEL   = 0x8086
cdef uint16_t PCI_DEVICE_ID_INTEL_440FX = 0x1237

cdef uint8_t PCI_HEADER_TYPE_STANDARD = 0
cdef uint8_t PCI_HEADER_TYPE_BRIDGE = 1
cdef uint8_t PCI_RESET_VALUE = 0x02


cdef uint8_t PCI_BAR0_ENABLED_MASK = 0x1
cdef uint8_t PCI_BAR1_ENABLED_MASK = 0x2
cdef uint8_t PCI_BAR2_ENABLED_MASK = 0x4
cdef uint8_t PCI_BAR3_ENABLED_MASK = 0x8
cdef uint8_t PCI_BAR4_ENABLED_MASK = 0x10
cdef uint8_t PCI_BAR5_ENABLED_MASK = 0x20

cdef uint32_t PCI_MEM_BASE = 0xc0000000
cdef uint32_t PCI_MEM_BASE_PLUS_LIMIT = 0xc0100000

cdef uint32_t VGA_ROM_BASE = 0xc0000

DEF PORTS_LEN = 32

cdef uint16_t PCI_CONTROLLER_PORTS[PORTS_LEN]
PCI_CONTROLLER_PORTS = (0x4d0, 0x4d1, 0xcf8, 0xcf9, 0xcfc, 0xcfd, 0xcfe, 0xcff, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t ATA1_PORTS[PORTS_LEN]
ATA1_PORTS = (0x1f0, 0x1f1, 0x1f2, 0x1f3, 0x1f4, 0x1f5, 0x1f6, 0x1f7, 0x3f6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t ATA2_PORTS[PORTS_LEN]
ATA2_PORTS = (0x170, 0x171, 0x172, 0x173, 0x174, 0x175, 0x176, 0x177, 0x376, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t ATA3_PORTS[PORTS_LEN]
ATA3_PORTS = (0x1e8, 0x1e9, 0x1ea, 0x1eb, 0x1ec, 0x1ed, 0x1ee, 0x1ef, 0x3e6, 0x3e7, 0x3ee, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t ATA4_PORTS[PORTS_LEN]
ATA4_PORTS = (0x168, 0x169, 0x16a, 0x16b, 0x16c, 0x16d, 0x16e, 0x16f, 0x366, 0x367, 0x36e, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

cdef uint16_t FDC_FIRST_PORTS[PORTS_LEN]
FDC_FIRST_PORTS = (0x3f2, 0x3f3, 0x3f4, 0x3f5, 0x3f7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t FDC_SECOND_PORTS[PORTS_LEN]
FDC_SECOND_PORTS = (0x372, 0x373, 0x374, 0x375, 0x377, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

cdef uint16_t VGA_READ_PORTS[PORTS_LEN]
VGA_READ_PORTS = (0x1ce, 0x1cf, 0x3b4, 0x3b5, 0x3ba, 0x3c0, 0x3c1, 0x3c2, 0x3c4, 0x3c5, 0x3cc, 0x3c7, 0x3c8, 0x3c9, 0x3ca, 0x3ce, 0x3cf, 0x3d4, 0x3d5, 0x3da, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t VGA_WRITE_PORTS[PORTS_LEN]
VGA_WRITE_PORTS = (0x1ce, 0x1cf, 0x3b4, 0x3b5, 0x3ba, 0x3c0, 0x3c2, 0x3c4, 0x3c5, 0x3c6, 0x3c7, 0x3c8, 0x3c9, 0x3ca, 0x3ce, 0x3cf, 0x3d4, 0x3d5, 0x3da, 0x400, 0x401, 0x402, 0x403, 0x500, 0x504, 0x8900, 0xb004, 0, 0, 0, 0, 0)

cdef uint16_t SERIAL_READ_PORTS[PORTS_LEN]
SERIAL_READ_PORTS = (0x3f8, 0x3f9, 0x3fa, 0x3fb, 0x3fc, 0x3fd, 0x3fe, 0x3ff, 0x2f8, 0x2f9, 0x2fa, 0x2fb, 0x2fc, 0x2fd, 0x2fe, 0x2ff, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t SERIAL_WRITE_PORTS[PORTS_LEN]
SERIAL_WRITE_PORTS = (0x3f8, 0x3f9, 0x3fa, 0x3fb, 0x3fc, 0x3ff, 0x2f8, 0x2f9, 0x2fa, 0x2fb, 0x2fc, 0x2ff, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t FPU_PORTS[PORTS_LEN]
FPU_PORTS = (0xf0, 0xf1, 0xf8, 0xfa, 0xfc, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

cdef uint16_t CMOS_PORTS[PORTS_LEN]
CMOS_PORTS = (0x70, 0x71, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t PIC_PORTS[PORTS_LEN]
PIC_PORTS = (0x20, 0x21, 0xa0, 0xa1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t PS2_PORTS[PORTS_LEN]
PS2_PORTS = (0x60, 0x61, 0x64, 0x92, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t PIT_PORTS[PORTS_LEN]
PIT_PORTS = (0x40, 0x41, 0x42, 0x43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

cdef uint16_t DMA_EXT_PAGE_REG_PORTS[PORTS_LEN]
DMA_EXT_PAGE_REG_PORTS = (0x80, 0x84, 0x85, 0x86, 0x88, 0x8c, 0x8d, 0x8e, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t DMA_MASTER_CONTROLLER_PORTS[PORTS_LEN]
DMA_MASTER_CONTROLLER_PORTS = (0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x81, 0x82, 0x83, 0x87, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) # 0x00,
cdef uint16_t DMA_SLAVE_CONTROLLER_PORTS[PORTS_LEN]
DMA_SLAVE_CONTROLLER_PORTS = (0x89, 0x8a, 0x8b, 0x8f, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xd0, 0xd2, 0xd4, 0xd6, 0xd8, 0xda, 0xdc, 0xde, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
cdef uint16_t PARALLEL_PORTS[PORTS_LEN]
PARALLEL_PORTS = (0x3bc, 0x3bd, 0x3be, 0x378, 0x379, 0x37a, 0x278, 0x279, 0x27a, 0x2bc, 0x2bd, 0x2be, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

DEF DMA_EXT_PAGE_REG_PORTS_TUPLE = (0x80, 0x84, 0x85, 0x86, 0x88, 0x8c, 0x8d, 0x8e)
DEF ATA1_PORTS_TUPLE = (0x1f0, 0x1f1, 0x1f2, 0x1f3, 0x1f4, 0x1f5, 0x1f6, 0x1f7, 0x3f6)
DEF ATA2_PORTS_TUPLE = (0x170, 0x171, 0x172, 0x173, 0x174, 0x175, 0x176, 0x177, 0x376)
DEF ATA3_PORTS_TUPLE = (0x1e8, 0x1e9, 0x1ea, 0x1eb, 0x1ec, 0x1ed, 0x1ee, 0x1ef, 0x3e6, 0x3e7, 0x3ee)
DEF ATA4_PORTS_TUPLE = (0x168, 0x169, 0x16a, 0x16b, 0x16c, 0x16d, 0x16e, 0x16f, 0x366, 0x367, 0x36e)
DEF SERIAL1_PORTS_TUPLE = (0x3f8, 0x3f9, 0x3fa, 0x3fb, 0x3fc, 0x3fd, 0x3fe, 0x3ff)
DEF SERIAL2_PORTS_TUPLE = (0x2f8, 0x2f9, 0x2fa, 0x2fb, 0x2fc, 0x2fd, 0x2fe, 0x2ff)


cdef uint64_t BITMASKS_80[9]
BITMASKS_80 = (0, 0x80, 0x8000, 0, 0x80000000, 0, 0, 0, 0x8000000000000000)
cdef uint64_t BITMASKS_FF[9]
BITMASKS_FF = (0, BITMASK_BYTE, BITMASK_WORD, 0, BITMASK_DWORD, 0, 0, 0, BITMASK_QWORD)

