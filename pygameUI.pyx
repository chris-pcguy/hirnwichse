import misc, pygame, threading, atexit, sys, time

include "globals.pxi"


cdef class pygameUI:
    cpdef public object main, vga
    cpdef object display, screen, font
    cpdef tuple screenSize, fontSize
    cpdef unsigned short screenWidth, screenHeight, fontWidth, fontHeight
    def __init__(self, object vga, object main):
        self.vga  = vga
        self.main = main
        self.display, self.screen, self.font = None, None, None
        self.screenSize = self.screenWidth, self.screenHeight = 720, 400 # 640, 400
        self.fontSize = self.fontWidth, self.fontHeight = self.screenWidth//80, self.screenHeight//25
    cpdef initPygame(self):
        pygame.display.init()
        pygame.font.init()
        pygame.display.set_caption("ChEmu - THE x86 Emulator written in Python. (c) 2011 by Christian Inci")
        self.display = pygame.display.set_mode(self.screenSize)
        self.screen = pygame.Surface(self.screenSize)
        self.font = pygame.font.SysFont( 'VeraMono',  self.fontHeight)
        atexit.register(self.quitFunc)
        pygame.event.set_blocked([ pygame.ACTIVEEVENT, pygame.MOUSEMOTION, pygame.MOUSEBUTTONUP, pygame.MOUSEBUTTONDOWN,\
                                   pygame.JOYAXISMOTION, pygame.JOYBALLMOTION, pygame.JOYHATMOTION, pygame.JOYBUTTONUP,\
                                   pygame.JOYBUTTONDOWN, pygame.VIDEORESIZE, pygame.USEREVENT ])
    cpdef quitFunc(self):
        try:
            pygame.font.quit()
            pygame.display.quit()
        except pygame.error:
            print(sys.exc_info())
        except:
            print(sys.exc_info())
        self.main.quitFunc()
    cpdef getCharRect(self, unsigned char x, unsigned char y):
        try:
            return pygame.Rect((self.fontWidth*x, self.fontHeight*y), self.fontSize)
        except pygame.error:
            print(sys.exc_info())
            return
        except:
            print(sys.exc_info())
            return
    cpdef tuple getColor(self, unsigned char color):
        if (color == 0x0): # black
            return (0, 0, 0)
        elif (color == 0x1): # blue
            return (0, 0, 0xa8)
        elif (color == 0x2): # green
            return (0, 0xa8, 0)
        elif (color == 0x3): # cyan
            return (0, 0xa8, 0xa8)
        elif (color == 0x4): # red
            return (0xa8, 0, 0)
        elif (color == 0x5): # magenta
            return (0xa8, 0, 0xa8)
        elif (color == 0x6): # brown
            return (0xa8, 0x57, 0)
        elif (color == 0x7): # light gray
            return (0xa8, 0xa8, 0xa8)
        elif (color == 0x8): # dark gray
            return (0x57, 0x57, 0x57)
        elif (color == 0x9): # light blue
            return (0x57, 0x57, 0xff)
        elif (color == 0xa): # light green
            return (0x57, 0xff, 0x57)
        elif (color == 0xb): # light cyan
            return (0x57, 0xff, 0xff)
        elif (color == 0xc): # light red
            return (0xff, 0x57, 0x57)
        elif (color == 0xd): # light magenta
            return (0xff, 0x57, 0xff)
        elif (color == 0xe): # yellow
            return (0xff, 0xff, 0x57)
        elif (color == 0xf): # white
            return (0xff, 0xff, 0xff)
        else:
            self.main.exitError('pygameUI: invalid color used. (color: {0:d})', color)
    cpdef object getBlankChar(self, tuple bgColor):
        cpdef object blankSurface
        blankSurface = pygame.Surface(self.fontSize)
        blankSurface.fill(bgColor)
        return blankSurface
    cpdef object putChar(self, unsigned char x, unsigned char y, str char, unsigned char colors): # returns rect
        cpdef object newRect, newChar, newBack
        cdef tuple fgColor, bgColor
        try:
            newRect = self.getCharRect(x, y)
            fgColor, bgColor = self.getColor(colors&0xf), self.getColor((colors&0xf0)>>4)
            newBack = self.getBlankChar(bgColor)
            if (char.isprintable()):
                #newChar = self.font.render(char, False, fgColor, bgColor)
                newChar = self.font.render(char, True, fgColor, bgColor)
                newBack.blit(newChar, ( (0, 0), self.fontSize ))
            self.screen.blit(newBack, newRect)
            return newRect
        except pygame.error:
            print(sys.exc_info())
        except:
            print(sys.exc_info())
    cpdef setRepeatRate(self, unsigned short delay, unsigned short interval):
        pygame.key.set_repeat(delay, interval)
    cpdef unsigned short keyToScancode(self, unsigned long key):
        if (key == pygame.K_ESCAPE):
            return 0x01
        elif (key == pygame.K_1):
            return 0x02
        elif (key == pygame.K_2):
            return 0x03
        elif (key == pygame.K_3):
            return 0x04
        elif (key == pygame.K_4):
            return 0x05
        elif (key == pygame.K_5):
            return 0x06
        elif (key == pygame.K_6):
            return 0x07
        elif (key == pygame.K_7):
            return 0x08
        elif (key == pygame.K_8):
            return 0x09
        elif (key == pygame.K_9):
            return 0x0a
        elif (key == pygame.K_0):
            return 0x0b
        elif (key == pygame.K_MINUS):
            return 0x0c
        elif (key == pygame.K_PLUS):
            return 0x0d
        elif (key == pygame.K_BACKSPACE):
            return 0x0e
        elif (key == pygame.K_TAB):
            return 0x0f
        elif (key == pygame.K_q):
            return 0x10
        elif (key == pygame.K_w):
            return 0x11
        elif (key == pygame.K_e):
            return 0x12
        elif (key == pygame.K_r):
            return 0x13
        elif (key == pygame.K_t):
            return 0x14
        elif (key == pygame.K_y):
            return 0x15
        elif (key == pygame.K_u):
            return 0x16
        elif (key == pygame.K_i):
            return 0x17
        elif (key == pygame.K_o):
            return 0x18
        elif (key == pygame.K_p):
            return 0x19
        elif (key == pygame.K_RETURN):
            return 0x1c
        elif (key == pygame.K_LCTRL):
            return 0x1d
        elif (key == pygame.K_a):
            return 0x1e
        elif (key == pygame.K_s):
            return 0x1f
        elif (key == pygame.K_d):
            return 0x20
        elif (key == pygame.K_f):
            return 0x21
        elif (key == pygame.K_g):
            return 0x22
        elif (key == pygame.K_h):
            return 0x23
        elif (key == pygame.K_j):
            return 0x24
        elif (key == pygame.K_k):
            return 0x25
        elif (key == pygame.K_l):
            return 0x26
        elif (key == pygame.K_LSHIFT):
            return 0x2a
        elif (key == pygame.K_z):
            return 0x2c
        elif (key == pygame.K_x):
            return 0x2d
        elif (key == pygame.K_c):
            return 0x2e
        elif (key == pygame.K_v):
            return 0x2f
        elif (key == pygame.K_b):
            return 0x30
        elif (key == pygame.K_n):
            return 0x31
        elif (key == pygame.K_m):
            return 0x32
        elif (key == pygame.K_RSHIFT):
            return 0x36
        elif (key == pygame.K_LALT):
            return 0x38
        elif (key == pygame.K_SPACE):
            return 0x39
        elif (key == pygame.K_F1):
            return 0x3b
        elif (key == pygame.K_F2):
            return 0x3c
        elif (key == pygame.K_F3):
            return 0x3d
        elif (key == pygame.K_F4):
            return 0x3e
        elif (key == pygame.K_F5):
            return 0x3f
        elif (key == pygame.K_F6):
            return 0x40
        elif (key == pygame.K_F7):
            return 0x41
        elif (key == pygame.K_F8):
            return 0x42
        elif (key == pygame.K_F9):
            return 0x43
        elif (key == pygame.K_F10):
            return 0x44
        elif (key == pygame.K_F11):
            return 0x57
        elif (key == pygame.K_F12):
            return 0x58
        elif (key == pygame.K_RCTRL):
            return 0xe01d
        elif (key == pygame.K_RALT):
            return 0xe038
        return 0x0000
    cpdef addKeyToBuffer(self, unsigned short key, unsigned char up): # if KEYUP: up=True, otherwise up=False
        cdef unsigned char escKey
        cdef unsigned char normalKey
        cpdef object keys = bytearray()
        if (self.main.platform.ps2.keyboardDisabled):
            return
        escKey = (key>>8)&0xff
        normalKey = key&0xff
        if (escKey != 0):
            keys += bytes([escKey])
        if (normalKey == 0):
            return
        if (up):
            normalKey |= 0x80
        keys += bytes([normalKey])
        ###self.main.printMsg("appendToOutBytes({0:s})", repr(keys))
        self.main.platform.ps2.appendToOutBytes(keys)
        self.main.platform.pic.raiseIrq(KBC_IRQ)
    cpdef handleEvent(self, object event):
        try:
            if (event.type == pygame.QUIT):
                self.quitFunc()
            elif (event.type == pygame.VIDEOEXPOSE):
                self.updateScreen(list())
            elif (event.type == pygame.KEYDOWN):
                ###self.main.printMsg("event.type == pygame.KEYDOWN")
                self.addKeyToBuffer(self.keyToScancode(event.key), False)
            elif (event.type == pygame.KEYUP):
                self.addKeyToBuffer(self.keyToScancode(event.key), True)
        except pygame.error:
            print(sys.exc_info())
        except:
            print(sys.exc_info())
    cpdef updateScreen(self, list rectList):
        try:
            if (self.display and self.screen and not self.main.quitEmu):
                self.display.blit(self.screen, ((0, 0), self.screenSize))
            pygame.display.update(rectList)
        except pygame.error:
            print(sys.exc_info())
        except:
            print(sys.exc_info())
    cpdef handleEvents(self):
        cpdef object event
        for event in pygame.event.get():
            ##self.main.printMsg("pygameUI::eventLoop: event: {0:s}", repr(event))
            self.handleEvent(event)
        ##self.main.printMsg("pygameUI::eventLoop: while done.")
    cpdef run(self):
        self.initPygame()

    