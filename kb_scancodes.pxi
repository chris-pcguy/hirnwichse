
# copied from the The Bochs Project. Thanks to them!



DEF TRANSLATION_8042 = (
  0xff,0x43,0x41,0x3f,0x3d,0x3b,0x3c,0x58,0x64,0x44,0x42,0x40,0x3e,0x0f,0x29,0x59,
  0x65,0x38,0x2a,0x70,0x1d,0x10,0x02,0x5a,0x66,0x71,0x2c,0x1f,0x1e,0x11,0x03,0x5b,
  0x67,0x2e,0x2d,0x20,0x12,0x05,0x04,0x5c,0x68,0x39,0x2f,0x21,0x14,0x13,0x06,0x5d,
  0x69,0x31,0x30,0x23,0x22,0x15,0x07,0x5e,0x6a,0x72,0x32,0x24,0x16,0x08,0x09,0x5f,
  0x6b,0x33,0x25,0x17,0x18,0x0b,0x0a,0x60,0x6c,0x34,0x35,0x26,0x27,0x19,0x0c,0x61,
  0x6d,0x73,0x28,0x74,0x1a,0x0d,0x62,0x6e,0x3a,0x36,0x1c,0x1b,0x75,0x2b,0x63,0x76,
  0x55,0x56,0x77,0x78,0x79,0x7a,0x0e,0x7b,0x7c,0x4f,0x7d,0x4b,0x47,0x7e,0x7f,0x6f,
  0x52,0x53,0x50,0x4c,0x4d,0x48,0x01,0x45,0x57,0x4e,0x51,0x4a,0x37,0x49,0x46,0x54,
  0x80,0x81,0x82,0x41,0x54,0x85,0x86,0x87,0x88,0x89,0x8a,0x8b,0x8c,0x8d,0x8e,0x8f,
  0x90,0x91,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9a,0x9b,0x9c,0x9d,0x9e,0x9f,
  0xa0,0xa1,0xa2,0xa3,0xa4,0xa5,0xa6,0xa7,0xa8,0xa9,0xaa,0xab,0xac,0xad,0xae,0xaf,
  0xb0,0xb1,0xb2,0xb3,0xb4,0xb5,0xb6,0xb7,0xb8,0xb9,0xba,0xbb,0xbc,0xbd,0xbe,0xbf,
  0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,0xc8,0xc9,0xca,0xcb,0xcc,0xcd,0xce,0xcf,
  0xd0,0xd1,0xd2,0xd3,0xd4,0xd5,0xd6,0xd7,0xd8,0xd9,0xda,0xdb,0xdc,0xdd,0xde,0xdf,
  0xe0,0xe1,0xe2,0xe3,0xe4,0xe5,0xe6,0xe7,0xe8,0xe9,0xea,0xeb,0xec,0xed,0xee,0xef,
  0xf0,0xf1,0xf2,0xf3,0xf4,0xf5,0xf6,0xf7,0xf8,0xf9,0xfa,0xfb,0xfc,0xfd,0xfe,0xff)


# Definition of scancodes make and break,
# for each set (mf1/xt , mf2/at , mf3/ps2)
# The table must be in BX_KEY order

# BX_KEY_NBKEYS = 119

cdef tuple SCANCODES = (
 ( # BX_KEY_CTRL_L ( ibm 58)
   ( b'\x1D', b'\x9D' ),
   ( b'\x14', b'\xF0\x14' ),
   ( b'\x11', b'\xF0\x11' ),
 ),

 ( # BX_KEY_SHIFT_L ( ibm 44)
   ( b'\x2A', b'\xAA' ),
   ( b'\x12', b'\xF0\x12' ),
   ( b'\x12', b'\xF0\x12' ),
 ),

 ( # BX_KEY_F1 ( ibm 112 )
   ( b'\x3B', b'\xBB' ),
   ( b'\x05', b'\xF0\x05' ),
   ( b'\x07', b'\xF0\x07' ),
 ),

 ( # BX_KEY_F2 ( ibm 113 )
   ( b'\x3C', b'\xBC' ),
   ( b'\x06', b'\xF0\x06' ),
   ( b'\x0F', b'\xF0\x0F' ),
 ),

 ( # BX_KEY_F3 ( ibm 114 )
   ( b'\x3D', b'\xBD' ),
   ( b'\x04', b'\xF0\x04' ),
   ( b'\x17', b'\xF0\x17' ),
 ),

 ( # BX_KEY_F4 ( ibm 115 )
   ( b'\x3E', b'\xBE' ),
   ( b'\x0C', b'\xF0\x0C' ),
   ( b'\x1F', b'\xF0\x1F' ),
 ),

 ( # BX_KEY_F5 ( ibm 116 )
   ( b'\x3F', b'\xBF' ),
   ( b'\x03', b'\xF0\x03' ),
   ( b'\x27', b'\xF0\x27' ),
 ),

 ( # BX_KEY_F6 ( ibm 117 )
   ( b'\x40', b'\xC0' ),
   ( b'\x0B', b'\xF0\x0B' ),
   ( b'\x2F', b'\xF0\x2F' ),
 ),

 ( # BX_KEY_F7 ( ibm 118 )
   ( b'\x41', b'\xC1' ),
   ( b'\x83', b'\xF0\x83' ),
   ( b'\x37', b'\xF0\x37' ),
),

 ( # BX_KEY_F8 ( ibm 119 )
   ( b'\x42', b'\xC2' ),
   ( b'\x0A', b'\xF0\x0A' ),
   ( b'\x3F', b'\xF0\x3F' ),
 ),

 ( # BX_KEY_F9 ( ibm 120 )
   ( b'\x43', b'\xC3' ),
   ( b'\x01', b'\xF0\x01' ),
   ( b'\x47', b'\xF0\x47' ),
 ),

 ( # BX_KEY_F10 ( ibm 121 )
   ( b'\x44', b'\xC4' ),
   ( b'\x09', b'\xF0\x09' ),
   ( b'\x4F', b'\xF0\x4F' ),
 ),

 ( # BX_KEY_F11 ( ibm 122 )
   ( b'\x57', b'\xD7' ),
   ( b'\x78', b'\xF0\x78' ),
   ( b'\x56', b'\xF0\x56' ),
 ),

 ( # BX_KEY_F12 ( ibm 123 )
   ( b'\x58', b'\xD8' ),
   ( b'\x07', b'\xF0\x07' ),
   ( b'\x5E', b'\xF0\x5E' ),
 ),

 ( # BX_KEY_CTRL_R ( ibm 64 )
   ( b'\xE0\x1D', b'\xE0\x9D' ),
   ( b'\xE0\x14', b'\xE0\xF0\x14' ),
   ( b'\x58',     b'\xF0\x58' ),
 ),

 ( # BX_KEY_SHIFT_R ( ibm 57 )
   ( b'\x36', b'\xB6' ),
   ( b'\x59', b'\xF0\x59' ),
   ( b'\x59', b'\xF0\x59' ),
 ),

 ( # BX_KEY_CAPS_LOCK ( ibm 30 )
   ( b'\x3A', b'\xBA' ),
   ( b'\x58', b'\xF0\x58' ),
   ( b'\x14', b'\xF0\x14' ),
 ),

 ( # BX_KEY_NUM_LOCK ( ibm 90 )
   ( b'\x45', b'\xC5' ),
   ( b'\x77', b'\xF0\x77' ),
   ( b'\x76', b'\xF0\x76' ),
 ),

 ( # BX_KEY_ALT_L ( ibm 60 )
   ( b'\x38', b'\xB8' ),
   ( b'\x11', b'\xF0\x11' ),
   ( b'\x19', b'\xF0\x19' ),
 ),

 ( # BX_KEY_ALT_R ( ibm 62 )
   ( b'\xE0\x38', b'\xE0\xB8' ),
   ( b'\xE0\x11', b'\xE0\xF0\x11' ),
   ( b'\x39',     b'\xF0\x39' ),
 ),

 ( # BX_KEY_A ( ibm 31 )
   ( b'\x1E', b'\x9E' ),
   ( b'\x1C', b'\xF0\x1C' ),
   ( b'\x1C', b'\xF0\x1C' ),
 ),

 ( # BX_KEY_B ( ibm 50 )
   ( b'\x30', b'\xB0' ),
   ( b'\x32', b'\xF0\x32' ),
   ( b'\x32', b'\xF0\x32' ),
 ),

 ( # BX_KEY_C ( ibm 48 )
   ( b'\x2E', b'\xAE' ),
   ( b'\x21', b'\xF0\x21' ),
   ( b'\x21', b'\xF0\x21' ),
 ),

 ( # BX_KEY_D ( ibm 33 )
   ( b'\x20', b'\xA0' ),
   ( b'\x23', b'\xF0\x23' ),
   ( b'\x23', b'\xF0\x23' ),
 ),

 ( # BX_KEY_E ( ibm 19 )
   ( b'\x12', b'\x92' ),
   ( b'\x24', b'\xF0\x24' ),
   ( b'\x24', b'\xF0\x24' ),
 ),

 ( # BX_KEY_F ( ibm 34 )
   ( b'\x21', b'\xA1' ),
   ( b'\x2B', b'\xF0\x2B' ),
   ( b'\x2B', b'\xF0\x2B' ),
 ),

 ( # BX_KEY_G ( ibm 35 )
   ( b'\x22', b'\xA2' ),
   ( b'\x34', b'\xF0\x34' ),
   ( b'\x34', b'\xF0\x34' ),
 ),

 ( # BX_KEY_H ( ibm 36 )
   ( b'\x23', b'\xA3' ),
   ( b'\x33', b'\xF0\x33' ),
   ( b'\x33', b'\xF0\x33' ),
 ),

 ( # BX_KEY_I ( ibm 24 )
   ( b'\x17', b'\x97' ),
   ( b'\x43', b'\xF0\x43' ),
   ( b'\x43', b'\xF0\x43' ),
 ),

 ( # BX_KEY_J ( ibm 37 )
   ( b'\x24', b'\xA4' ),
   ( b'\x3B', b'\xF0\x3B' ),
   ( b'\x3B', b'\xF0\x3B' ),
 ),

 ( # BX_KEY_K ( ibm 38 )
   ( b'\x25', b'\xA5' ),
   ( b'\x42', b'\xF0\x42' ),
   ( b'\x42', b'\xF0\x42' ),
 ),

 ( # BX_KEY_L ( ibm 39 )
   ( b'\x26', b'\xA6' ),
   ( b'\x4B', b'\xF0\x4B' ),
   ( b'\x4B', b'\xF0\x4B' ),
 ),

 ( # BX_KEY_M ( ibm 52 )
   ( b'\x32', b'\xB2' ),
   ( b'\x3A', b'\xF0\x3A' ),
   ( b'\x3A', b'\xF0\x3A' ),
 ),

 ( # BX_KEY_N ( ibm 51 )
   ( b'\x31', b'\xB1' ),
   ( b'\x31', b'\xF0\x31' ),
   ( b'\x31', b'\xF0\x31' ),
 ),

 ( # BX_KEY_O ( ibm 25 )
   ( b'\x18', b'\x98' ),
   ( b'\x44', b'\xF0\x44' ),
   ( b'\x44', b'\xF0\x44' ),
 ),

 ( # BX_KEY_P ( ibm 26 )
   ( b'\x19', b'\x99' ),
   ( b'\x4D', b'\xF0\x4D' ),
   ( b'\x4D', b'\xF0\x4D' ),
 ),

 ( # BX_KEY_Q ( ibm 17 )
   ( b'\x10', b'\x90' ),
   ( b'\x15', b'\xF0\x15' ),
   ( b'\x15', b'\xF0\x15' ),
 ),

 ( # BX_KEY_R ( ibm 20 )
   ( b'\x13', b'\x93' ),
   ( b'\x2D', b'\xF0\x2D' ),
   ( b'\x2D', b'\xF0\x2D' ),
 ),

 ( # BX_KEY_S ( ibm 32 )
   ( b'\x1F', b'\x9F' ),
   ( b'\x1B', b'\xF0\x1B' ),
   ( b'\x1B', b'\xF0\x1B' ),
 ),

 ( # BX_KEY_T ( ibm 21 )
   ( b'\x14', b'\x94' ),
   ( b'\x2C', b'\xF0\x2C' ),
   ( b'\x2C', b'\xF0\x2C' ),
 ),

 ( # BX_KEY_U ( ibm 23 )
   ( b'\x16', b'\x96' ),
   ( b'\x3C', b'\xF0\x3C' ),
   ( b'\x3C', b'\xF0\x3C' ),
 ),

 ( # BX_KEY_V ( ibm 49 )
   ( b'\x2F', b'\xAF' ),
   ( b'\x2A', b'\xF0\x2A' ),
   ( b'\x2A', b'\xF0\x2A' ),
 ),

 ( # BX_KEY_W ( ibm 18 )
   ( b'\x11', b'\x91' ),
   ( b'\x1D', b'\xF0\x1D' ),
   ( b'\x1D', b'\xF0\x1D' ),
 ),

 ( # BX_KEY_X ( ibm 47 )
   ( b'\x2D', b'\xAD' ),
   ( b'\x22', b'\xF0\x22' ),
   ( b'\x22', b'\xF0\x22' ),
 ),

 ( # BX_KEY_Y ( ibm 22 )
   ( b'\x15', b'\x95' ),
   ( b'\x35', b'\xF0\x35' ),
   ( b'\x35', b'\xF0\x35' ),
 ),

 ( # BX_KEY_Z ( ibm 46 )
   ( b'\x2C', b'\xAC' ),
   ( b'\x1A', b'\xF0\x1A' ),
   ( b'\x1A', b'\xF0\x1A' ),
 ),

 ( # BX_KEY_0 ( ibm 11 )
   ( b'\x0B', b'\x8B' ),
   ( b'\x45', b'\xF0\x45' ),
   ( b'\x45', b'\xF0\x45' ),
 ),

 ( # BX_KEY_1 ( ibm 2 )
   ( b'\x02', b'\x82' ),
   ( b'\x16', b'\xF0\x16' ),
   ( b'\x16', b'\xF0\x16' ),
 ),

 ( # BX_KEY_2 ( ibm 3 )
   ( b'\x03', b'\x83' ),
   ( b'\x1E', b'\xF0\x1E' ),
   ( b'\x1E', b'\xF0\x1E' ),
 ),

 ( # BX_KEY_3 ( ibm 4 )
   ( b'\x04', b'\x84' ),
   ( b'\x26', b'\xF0\x26' ),
   ( b'\x26', b'\xF0\x26' ),
 ),

 ( # BX_KEY_4 ( ibm 5 )
   ( b'\x05', b'\x85' ),
   ( b'\x25', b'\xF0\x25' ),
   ( b'\x25', b'\xF0\x25' ),
 ),

 ( # BX_KEY_5 ( ibm 6 )
   ( b'\x06', b'\x86' ),
   ( b'\x2E', b'\xF0\x2E' ),
   ( b'\x2E', b'\xF0\x2E' ),
 ),

 ( # BX_KEY_6 ( ibm 7 )
   ( b'\x07', b'\x87' ),
   ( b'\x36', b'\xF0\x36' ),
   ( b'\x36', b'\xF0\x36' ),
 ),

 ( # BX_KEY_7 ( ibm 8 )
   ( b'\x08', b'\x88' ),
   ( b'\x3D', b'\xF0\x3D' ),
   ( b'\x3D', b'\xF0\x3D' ),
 ),

 ( # BX_KEY_8 ( ibm 9 )
   ( b'\x09', b'\x89' ),
   ( b'\x3E', b'\xF0\x3E' ),
   ( b'\x3E', b'\xF0\x3E' ),
 ),

 ( # BX_KEY_9 ( ibm 10 )
   ( b'\x0A', b'\x8A' ),
   ( b'\x46', b'\xF0\x46' ),
   ( b'\x46', b'\xF0\x46' ),
 ),

 ( # BX_KEY_ESC ( ibm 110 )
   ( b'\x01', b'\x81' ),
   ( b'\x76', b'\xF0\x76' ),
   ( b'\x08', b'\xF0\x08' ),
 ),

 ( # BX_KEY_SPACE ( ibm 61 )
   ( b'\x39', b'\xB9' ),
   ( b'\x29', b'\xF0\x29' ),
   ( b'\x29', b'\xF0\x29' ),
 ),

 ( # BX_KEY_SINGLE_QUOTE ( ibm 41 )
   ( b'\x28', b'\xA8' ),
   ( b'\x52', b'\xF0\x52' ),
   ( b'\x52', b'\xF0\x52' ),
 ),

 ( # BX_KEY_COMMA ( ibm 53 )
   ( b'\x33', b'\xB3' ),
   ( b'\x41', b'\xF0\x41' ),
   ( b'\x41', b'\xF0\x41' ),
 ),

 ( # BX_KEY_PERIOD ( ibm 54 )
   ( b'\x34', b'\xB4' ),
   ( b'\x49', b'\xF0\x49' ),
   ( b'\x49', b'\xF0\x49' ),
 ),

 ( # BX_KEY_SLASH ( ibm 55 )
   ( b'\x35', b'\xB5' ),
   ( b'\x4A', b'\xF0\x4A' ),
   ( b'\x4A', b'\xF0\x4A' ),
 ),

 ( # BX_KEY_SEMICOLON ( ibm 40 )
   ( b'\x27', b'\xA7' ),
   ( b'\x4C', b'\xF0\x4C' ),
   ( b'\x4C', b'\xF0\x4C' ),
 ),

 ( # BX_KEY_EQUALS ( ibm 13 )
   ( b'\x0D', b'\x8D' ),
   ( b'\x55', b'\xF0\x55' ),
   ( b'\x55', b'\xF0\x55' ),
 ),

 ( # BX_KEY_LEFT_BRACKET ( ibm 27 )
   ( b'\x1A', b'\x9A' ),
   ( b'\x54', b'\xF0\x54' ),
   ( b'\x54', b'\xF0\x54' ),
 ),

 ( # BX_KEY_BACKSLASH ( ibm 42, 29)
   ( b'\x2B', b'\xAB' ),
   ( b'\x5D', b'\xF0\x5D' ),
   ( b'\x53', b'\xF0\x53' ),
 ),

 ( # BX_KEY_RIGHT_BRACKET ( ibm 28 )
   ( b'\x1B', b'\x9B' ),
   ( b'\x5B', b'\xF0\x5B' ),
   ( b'\x5B', b'\xF0\x5B' ),
 ),

 ( # BX_KEY_MINUS ( ibm 12 )
   ( b'\x0C', b'\x8C' ),
   ( b'\x4E', b'\xF0\x4E' ),
   ( b'\x4E', b'\xF0\x4E' ),
 ),

 ( # BX_KEY_GRAVE ( ibm 1 )
   ( b'\x29', b'\xA9' ),
   ( b'\x0E', b'\xF0\x0E' ),
   ( b'\x0E', b'\xF0\x0E' ),
 ),

 ( # BX_KEY_BACKSPACE ( ibm 15 )
   ( b'\x0E', b'\x8E' ),
   ( b'\x66', b'\xF0\x66' ),
   ( b'\x66', b'\xF0\x66' ),
 ),

 ( # BX_KEY_ENTER ( ibm 43 )
   ( b'\x1C', b'\x9C' ),
   ( b'\x5A', b'\xF0\x5A' ),
   ( b'\x5A', b'\xF0\x5A' ),
 ),

 ( # BX_KEY_TAB ( ibm 16 )
   ( b'\x0F', b'\x8F' ),
   ( b'\x0D', b'\xF0\x0D' ),
   ( b'\x0D', b'\xF0\x0D' ),
 ),

 ( # BX_KEY_LEFT_BACKSLASH ( ibm 45 )
   ( b'\x56', b'\xD6' ),
   ( b'\x61', b'\xF0\x61' ),
   ( b'\x13', b'\xF0\x13' ),
 ),

 ( # BX_KEY_PRINT ( ibm 124 )
   ( b'\xE0\x2A\xE0\x37', b'\xE0\xB7\xE0\xAA' ),
   ( b'\xE0\x12\xE0\x7C', b'\xE0\xF0\x7C\xE0\xF0\x12' ),
   ( b'\x57' ,     b'\xF0\x57' ),
 ),

 ( # BX_KEY_SCRL_LOCK ( ibm 125 )
   ( b'\x46', b'\xC6' ),
   ( b'\x7E', b'\xF0\x7E' ),
   ( b'\x5F', b'\xF0\x5F' ),
 ),

 ( # BX_KEY_PAUSE ( ibm 126 )
   ( b'\xE1\x1D\x45\xE1\x9D\xC5',         b'' ),
   ( b'\xE1\x14\x77\xE1\xF0\x14\xF0\x77', b'' ),
   ( b'\x62',                             b'\xF0\x62' ),
 ),

 ( # BX_KEY_INSERT ( ibm 75 )
   ( b'\xE0\x52', b'\xE0\xD2' ),
   ( b'\xE0\x70', b'\xE0\xF0\x70' ),
   ( b'\x67',     b'\xF0\x67' ),
 ),

 ( # BX_KEY_DELETE ( ibm 76 )
   ( b'\xE0\x53', b'\xE0\xD3' ),
   ( b'\xE0\x71', b'\xE0\xF0\x71' ),
   ( b'\x64',     b'\xF0\x64' ),
 ),

 ( # BX_KEY_HOME ( ibm 80 )
   ( b'\xE0\x47', b'\xE0\xC7' ),
   ( b'\xE0\x6C', b'\xE0\xF0\x6C' ),
   ( b'\x6E',     b'\xF0\x6E' ),
 ),

 ( # BX_KEY_END ( ibm 81 )
   ( b'\xE0\x4F', b'\xE0\xCF' ),
   ( b'\xE0\x69', b'\xE0\xF0\x69' ),
   ( b'\x65',     b'\xF0\x65' ),
 ),

 ( # BX_KEY_PAGE_UP ( ibm 85 )
   ( b'\xE0\x49', b'\xE0\xC9' ),
   ( b'\xE0\x7D', b'\xE0\xF0\x7D' ),
   ( b'\x6F',     b'\xF0\x6F' ),
 ),

 ( # BX_KEY_PAGE_DOWN ( ibm 86 )
   ( b'\xE0\x51', b'\xE0\xD1' ),
   ( b'\xE0\x7A', b'\xE0\xF0\x7A' ),
   ( b'\x6D',     b'\xF0\x6D' ),
 ),

 ( # BX_KEY_KP_ADD ( ibm 106 )
   ( b'\x4E', b'\xCE' ),
   ( b'\x79', b'\xF0\x79' ),
   ( b'\x7C', b'\xF0\x7C' ),
 ),

 ( # BX_KEY_KP_SUBTRACT ( ibm 105 )
   ( b'\x4A', b'\xCA' ),
   ( b'\x7B', b'\xF0\x7B' ),
   ( b'\x84', b'\xF0\x84' ),
 ),

 ( # BX_KEY_KP_END ( ibm 93 )
   ( b'\x4F', b'\xCF' ),
   ( b'\x69', b'\xF0\x69' ),
   ( b'\x69', b'\xF0\x69' ),
 ),

 ( # BX_KEY_KP_DOWN ( ibm 98 )
   ( b'\x50', b'\xD0' ),
   ( b'\x72', b'\xF0\x72' ),
   ( b'\x72', b'\xF0\x72' ),
 ),

 ( # BX_KEY_KP_PAGE_DOWN ( ibm 103 )
   ( b'\x51', b'\xD1' ),
   ( b'\x7A', b'\xF0\x7A' ),
   ( b'\x7A', b'\xF0\x7A' ),
 ),

 ( # BX_KEY_KP_LEFT ( ibm 92 )
   ( b'\x4B', b'\xCB' ),
   ( b'\x6B', b'\xF0\x6B' ),
   ( b'\x6B', b'\xF0\x6B' ),
 ),

 ( # BX_KEY_KP_RIGHT ( ibm 102 )
   ( b'\x4D', b'\xCD' ),
   ( b'\x74', b'\xF0\x74' ),
   ( b'\x74', b'\xF0\x74' ),
 ),

 ( # BX_KEY_KP_HOME ( ibm 91 )
   ( b'\x47', b'\xC7' ),
   ( b'\x6C', b'\xF0\x6C' ),
   ( b'\x6C', b'\xF0\x6C' ),
 ),

 ( # BX_KEY_KP_UP ( ibm 96 )
   ( b'\x48', b'\xC8' ),
   ( b'\x75', b'\xF0\x75' ),
   ( b'\x75', b'\xF0\x75' ),
 ),

 ( # BX_KEY_KP_PAGE_UP ( ibm 101 )
   ( b'\x49', b'\xC9' ),
   ( b'\x7D', b'\xF0\x7D' ),
   ( b'\x7D', b'\xF0\x7D' ),
 ),

 ( # BX_KEY_KP_INSERT ( ibm 99 )
   ( b'\x52', b'\xD2' ),
   ( b'\x70', b'\xF0\x70' ),
   ( b'\x70', b'\xF0\x70' ),
 ),

 ( # BX_KEY_KP_DELETE ( ibm 104 )
   ( b'\x53', b'\xD3' ),
   ( b'\x71', b'\xF0\x71' ),
   ( b'\x71', b'\xF0\x71' ),
 ),

 ( # BX_KEY_KP_5 ( ibm 97 )
   ( b'\x4C', b'\xCC' ),
   ( b'\x73', b'\xF0\x73' ),
   ( b'\x73', b'\xF0\x73' ),
 ),

 ( # BX_KEY_UP ( ibm 83 )
   ( b'\xE0\x48', b'\xE0\xC8' ),
   ( b'\xE0\x75', b'\xE0\xF0\x75' ),
   ( b'\x63',     b'\xF0\x63' ),
 ),

 ( # BX_KEY_DOWN ( ibm 84 )
   ( b'\xE0\x50', b'\xE0\xD0' ),
   ( b'\xE0\x72', b'\xE0\xF0\x72' ),
   ( b'\x60',     b'\xF0\x60' ),
 ),

 ( # BX_KEY_LEFT ( ibm 79 )
   ( b'\xE0\x4B', b'\xE0\xCB' ),
   ( b'\xE0\x6B', b'\xE0\xF0\x6B' ),
   ( b'\x61',     b'\xF0\x61' ),
 ),

 ( # BX_KEY_RIGHT ( ibm 89 )
   ( b'\xE0\x4D', b'\xE0\xCD' ),
   ( b'\xE0\x74', b'\xE0\xF0\x74' ),
   ( b'\x6A',     b'\xF0\x6A' ),
 ),

 ( # BX_KEY_KP_ENTER ( ibm 108 )
   ( b'\xE0\x1C', b'\xE0\x9C' ),
   ( b'\xE0\x5A', b'\xE0\xF0\x5A' ),
   ( b'\x79',     b'\xF0\x79' ),
 ),

 ( # BX_KEY_KP_MULTIPLY ( ibm 100 )
   ( b'\x37', b'\xB7' ),
   ( b'\x7C', b'\xF0\x7C' ),
   ( b'\x7E', b'\xF0\x7E' ),
 ),

 ( # BX_KEY_KP_DIVIDE ( ibm 95 )
   ( b'\xE0\x35', b'\xE0\xB5' ),
   ( b'\xE0\x4A', b'\xE0\xF0\x4A' ),
   ( b'\x77',     b'\xF0\x77' ),
 ),

 ( # BX_KEY_WIN_L
   ( b'\xE0\x5B', b'\xE0\xDB' ),
   ( b'\xE0\x1F', b'\xE0\xF0\x1F' ),
   ( b'\x8B',     b'\xF0\x8B' ),
 ),

 ( # BX_KEY_WIN_R
   ( b'\xE0\x5C', b'\xE0\xDC' ),
   ( b'\xE0\x27', b'\xE0\xF0\x27' ),
   ( b'\x8C',     b'\xF0\x8C' ),
 ),

 ( # BX_KEY_MENU
   ( b'\xE0\x5D', b'\xE0\xDD' ),
   ( b'\xE0\x2F', b'\xE0\xF0\x2F' ),
   ( b'\x8D',     b'\xF0\x8D' ),
 ),

 ( # BX_KEY_ALT_SYSREQ
   ( b'\x54',   b'\xD4' ),
   ( b'\x84',   b'\xF0\x84' ),
   ( b'\x57',   b'\xF0\x57' ),
 ),

 ( # BX_KEY_CTRL_BREAK
   ( b'\xE0\x46', b'\xE0\xC6' ),
   ( b'\xE0\x7E', b'\xE0\xF0\x7E' ),
   ( b'\x62',     b'\xF0\x62' ),
 ),

 ( # BX_KEY_INT_BACK
   ( b'\xE0\x6A', b'\xE0\xEA' ),
   ( b'\xE0\x38', b'\xE0\xF0\x38' ),
   ( b'\x38',     b'\xF0\x38' ),
 ),

 ( # BX_KEY_INT_FORWARD
   ( b'\xE0\x69', b'\xE0\xE9' ),
   ( b'\xE0\x30', b'\xE0\xF0\x30' ),
   ( b'\x30',     b'\xF0\x30' ),
 ),

 ( # BX_KEY_INT_STOP
   ( b'\xE0\x68', b'\xE0\xE8' ),
   ( b'\xE0\x28', b'\xE0\xF0\x28' ),
   ( b'\x28',     b'\xF0\x28' ),
 ),

 ( # BX_KEY_INT_MAIL
   ( b'\xE0\x6C', b'\xE0\xEC' ),
   ( b'\xE0\x48', b'\xE0\xF0\x48' ),
   ( b'\x48',     b'\xF0\x48' ),
 ),

 ( # BX_KEY_INT_SEARCH
   ( b'\xE0\x65', b'\xE0\xE5' ),
   ( b'\xE0\x10', b'\xE0\xF0\x10' ),
   ( b'\x10',     b'\xF0\x10' ),
 ),

 ( # BX_KEY_INT_FAV
   ( b'\xE0\x66', b'\xE0\xE6' ),
   ( b'\xE0\x18', b'\xE0\xF0\x18' ),
   ( b'\x18',     b'\xF0\x18' ),
 ),

 ( # BX_KEY_INT_HOME
   ( b'\xE0\x32', b'\xE0\xB2' ),
   ( b'\xE0\x3A', b'\xE0\xF0\x3A' ),
   ( b'\x97',     b'\xF0\x97' ),
 ),

 ( # BX_KEY_POWER_MYCOMP
   ( b'\xE0\x6B', b'\xE0\xEB' ),
   ( b'\xE0\x40', b'\xE0\xF0\x40' ),
   ( b'\x40',     b'\xF0\x40' ),
 ),

 ( # BX_KEY_POWER_CALC
   ( b'\xE0\x21', b'\xE0\xA1' ),
   ( b'\xE0\x2B', b'\xE0\xF0\x2B' ),
   ( b'\x99',     b'\xF0\x99' ),
 ),

 ( # BX_KEY_POWER_SLEEP
   ( b'\xE0\x5F', b'\xE0\xDF' ),
   ( b'\xE0\x3F', b'\xE0\xF0\x3F' ),
   ( b'\x7F',     b'\xF0\x7F' ), # TODO: BUG: Don't use \x7F here!!!!! HACK: use cython's 'cdef tuple' instead of cython's 'DEF' (run-time instead of compile-time)
 ),

 ( # BX_KEY_POWER_POWER
   ( b'\xE0\x5E', b'\xE0\xDE' ),
   ( b'\xE0\x37', b'\xE0\xF0\x37' ),
   ( b'',         b'' ),
 ),

 ( # BX_KEY_POWER_WAKE
   ( b'\xE0\x63', b'\xE0\xE3' ),
   ( b'\xE0\x5E', b'\xE0\xF0\x5E' ),
   ( b'',         b'' ),
 ))



