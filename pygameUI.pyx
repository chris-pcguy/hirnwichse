
from traceback import print_exc
from atexit import register
import numpy
import pygame

include "globals.pxi"

cdef class PygameUI:
    def __init__(self, object vga, object main):
        self.vga  = vga
        self.main = main
        self.screen = None
        self.screenSize = 720, 400
        self.charSize = (UI_CHAR_WIDTH, 16)
        self.fontData = b'\x00'*VGA_FONTAREA_SIZE
    cpdef initPygame(self):
        pygame.display.init()
        pygame.display.set_caption('ChEmu - THE x86 Emulator written in Python. (c) 2011-2012 by Christian Inci')
        self.screen = pygame.display.set_mode(self.screenSize)
        register(self.quitFunc)
        pygame.event.set_blocked([ pygame.ACTIVEEVENT, pygame.MOUSEMOTION, pygame.MOUSEBUTTONDOWN, pygame.MOUSEBUTTONUP,\
                                   pygame.JOYAXISMOTION, pygame.JOYBALLMOTION, pygame.JOYHATMOTION, pygame.JOYBUTTONDOWN,\
                                   pygame.JOYBUTTONUP, pygame.VIDEORESIZE, pygame.USEREVENT ])
        self.setRepeatRate(500, 10)
    cpdef quitFunc(self):
        try:
            pygame.display.quit()
        except pygame.error:
            print(print_exc())
        except (SystemExit, KeyboardInterrupt):
            print(print_exc())
            self.main.quitEmu = True
            self.main.exitError('quitFunc: (SystemExit, KeyboardInterrupt) exception, exiting...)', exitNow=True)
        except:
            print(print_exc())
        self.main.quitEmu = True
        self.main.quitFunc()
    cpdef clearScreen(self):
        pass
        #self.screen.fill((0, 0, 0))
    cpdef object getCharRect(self, unsigned char x, unsigned char y):
        try:
            return pygame.Rect((self.charSize[0]*x, self.charSize[1]*y), self.charSize)
        except pygame.error:
            print(print_exc())
        except (SystemExit, KeyboardInterrupt):
            print(print_exc())
            self.main.quitEmu = True
            self.main.exitError('getCharRect: (SystemExit, KeyboardInterrupt) exception, exiting...)', exitNow=True)
        except:
            print(print_exc())
        return None
    cpdef object getBlankChar(self, tuple bgColor):
        cpdef object blankSurface
        blankSurface = pygame.Surface(self.charSize)
        blankSurface.fill(bgColor)
        return blankSurface
    cpdef object putChar(self, unsigned char x, unsigned char y, unsigned char character, unsigned char colors): # returns rect
        cpdef object newRect, newChar, charArray
        cdef bytes charData
        cdef str lineData
        cdef unsigned int i, j
        cdef tuple fgColor, bgColor
        try:
            newRect = self.getCharRect(x, y)
            fgColor = self.vga.getColor(colors&0xf)
            colors >>= 4
            if (self.msbBlink):
                bgColor = self.vga.getColor(colors&0x7)
            else:
                bgColor = self.vga.getColor(colors)
            charArray = numpy.ones((self.charSize[1], self.charSize[0], 3), dtype=numpy.uint8)
            charArray *= bgColor
            # It's not a good idea to render a character if fgColor == bgColor
            #   as it wouldn't be readable.
            if (fgColor != bgColor):
                i = character*self.charSize[1]
                charData = self.fontData[i:i+self.charSize[1]]
                for i in range(len(charData)):
                    j = charData[i]
                    if (self.replicate8Bit and (character&0xe0==0xc0)):
                        j = (j << 1) | (j&1)
                    else:
                        j <<= 1
                    lineData = '{0:09b}'.format(j)
                    for j in range(len(lineData)):
                        if (int(lineData[j])):
                            charArray[i][j] = fgColor
            newChar = pygame.surfarray.make_surface(charArray.transpose((1, 0, 2)))
            self.screen.blit(newChar, newRect)
            return newRect
        except pygame.error:
            print(print_exc())
        except (SystemExit, KeyboardInterrupt):
            print(print_exc())
            self.main.quitEmu = True
            self.main.exitError('putChar: (SystemExit, KeyboardInterrupt) exception, exiting...)', exitNow=True)
        except:
            print(print_exc())
    cpdef setRepeatRate(self, unsigned short delay, unsigned short interval):
        pygame.key.set_repeat(delay, interval)
    cdef unsigned char keyToScancode(self, unsigned short key):
        if (key == pygame.K_LCTRL):
            return 0x00
        elif (key == pygame.K_LSHIFT):
            return 0x01
        elif (key == pygame.K_F1):
            return 0x02
        elif (key == pygame.K_F2):
            return 0x03
        elif (key == pygame.K_F3):
            return 0x04
        elif (key == pygame.K_F4):
            return 0x05
        elif (key == pygame.K_F5):
            return 0x06
        elif (key == pygame.K_F6):
            return 0x07
        elif (key == pygame.K_F7):
            return 0x08
        elif (key == pygame.K_F8):
            return 0x09
        elif (key == pygame.K_F9):
            return 0x0a
        elif (key == pygame.K_F10):
            return 0x0b
        elif (key == pygame.K_F11):
            return 0x0c
        elif (key == pygame.K_F12):
            return 0x0d
        elif (key == pygame.K_RCTRL):
            return 0x0e
        elif (key == pygame.K_RSHIFT):
            return 0x0f
        elif (key == pygame.K_CAPSLOCK):
            return 0x10
        elif (key == pygame.K_NUMLOCK):
            return 0x11
        elif (key == pygame.K_LALT):
            return 0x12
        elif (key == pygame.K_RALT):
            return 0x13
        elif (key == pygame.K_a):
            return 0x14
        elif (key == pygame.K_b):
            return 0x15
        elif (key == pygame.K_c):
            return 0x16
        elif (key == pygame.K_d):
            return 0x17
        elif (key == pygame.K_e):
            return 0x18
        elif (key == pygame.K_f):
            return 0x19
        elif (key == pygame.K_g):
            return 0x1a
        elif (key == pygame.K_h):
            return 0x1b
        elif (key == pygame.K_i):
            return 0x1c
        elif (key == pygame.K_j):
            return 0x1d
        elif (key == pygame.K_k):
            return 0x1e
        elif (key == pygame.K_l):
            return 0x1f
        elif (key == pygame.K_m):
            return 0x20
        elif (key == pygame.K_n):
            return 0x21
        elif (key == pygame.K_o):
            return 0x22
        elif (key == pygame.K_p):
            return 0x23
        elif (key == pygame.K_q):
            return 0x24
        elif (key == pygame.K_r):
            return 0x25
        elif (key == pygame.K_s):
            return 0x26
        elif (key == pygame.K_t):
            return 0x27
        elif (key == pygame.K_u):
            return 0x28
        elif (key == pygame.K_v):
            return 0x29
        elif (key == pygame.K_w):
            return 0x2a
        elif (key == pygame.K_x):
            return 0x2b
        elif (key == pygame.K_y):
            return 0x2c
        elif (key == pygame.K_z):
            return 0x2d
        elif (key == pygame.K_0):
            return 0x2e
        elif (key == pygame.K_1):
            return 0x2f
        elif (key == pygame.K_2):
            return 0x30
        elif (key == pygame.K_3):
            return 0x31
        elif (key == pygame.K_4):
            return 0x32
        elif (key == pygame.K_5):
            return 0x33
        elif (key == pygame.K_6):
            return 0x34
        elif (key == pygame.K_7):
            return 0x35
        elif (key == pygame.K_8):
            return 0x36
        elif (key == pygame.K_9):
            return 0x37
        elif (key == pygame.K_ESCAPE):
            return 0x38
        elif (key == pygame.K_SPACE):
            return 0x39
        elif (key == pygame.K_QUOTE):
            return 0x3a
        elif (key == pygame.K_COMMA):
            return 0x3b
        elif (key == pygame.K_PERIOD):
            return 0x3c
        elif (key == pygame.K_SLASH):
            return 0x3d
        elif (key == pygame.K_SEMICOLON):
            return 0x3e
        elif (key == pygame.K_EQUALS):
            return 0x3f
        elif (key == pygame.K_LEFTBRACKET):
            return 0x40
        elif (key == pygame.K_BACKSLASH):
            return 0x41
        elif (key == pygame.K_RIGHTBRACKET):
            return 0x42
        elif (key == pygame.K_MINUS):
            return 0x43
        elif (key == pygame.K_BACKQUOTE):
            return 0x44
        elif (key == pygame.K_BACKSPACE):
            return 0x45
        elif (key == pygame.K_RETURN):
            return 0x46
        elif (key == pygame.K_TAB):
            return 0x47
        #elif (key == pygame.K_BACKSLASH): # left backslash??
        #    return 0x48
        elif (key == pygame.K_PRINT):
            return 0x49
        elif (key == pygame.K_SCROLLOCK):
            return 0x4a
        elif (key == pygame.K_PAUSE):
            return 0x4b
        elif (key == pygame.K_INSERT):
            return 0x4c
        elif (key == pygame.K_DELETE):
            return 0x4d
        elif (key == pygame.K_HOME):
            return 0x4e
        elif (key == pygame.K_END):
            return 0x4f
        elif (key == pygame.K_PAGEUP):
            return 0x50
        elif (key == pygame.K_PAGEDOWN):
            return 0x51
        elif (key == pygame.K_KP_PLUS):
            return 0x52
        elif (key == pygame.K_KP_MINUS):
            return 0x53
        #elif (key == pygame.K_KP_END):
        #    return 0x54
        #elif (key == pygame.K_KP_DOWN):
        #    return 0x55
        #elif (key == pygame.K_KP_PAGEDOWN):
        #    return 0x56
        #elif (key == pygame.K_KP_LEFT):
        #    return 0x57
        #elif (key == pygame.K_KP_RIGHT):
        #    return 0x58
        #elif (key == pygame.K_KP_HOME):
        #    return 0x59
        #elif (key == pygame.K_KP_UP):
        #    return 0x5a
        #elif (key == pygame.K_KP_PAGEUP):
        #    return 0x5b
        #elif (key == pygame.K_KP_INSERT):
        #    return 0x5c
        #elif (key == pygame.K_KP_DELETE):
        #    return 0x5d
        elif (key == pygame.K_KP5):
            return 0x5e
        elif (key == pygame.K_UP):
            return 0x5f
        elif (key == pygame.K_DOWN):
            return 0x60
        elif (key == pygame.K_LEFT):
            return 0x61
        elif (key == pygame.K_RIGHT):
            return 0x62
        elif (key == pygame.K_KP_ENTER):
            return 0x63
        elif (key == pygame.K_KP_MULTIPLY):
            return 0x64
        elif (key == pygame.K_KP_DIVIDE):
            return 0x65
        elif (key == pygame.K_LSUPER):
            return 0x66
        elif (key == pygame.K_RSUPER):
            return 0x67
        elif (key == pygame.K_MENU):
            return 0x68
        elif (key == pygame.K_SYSREQ): # OR SYSRQ?
            return 0x69
        elif (key == pygame.K_BREAK):
            return 0x6a
        self.main.notice("keyToScancode: unknown key. (keyId: {0:d}, keyName: {1:s})", key, repr(pygame.key.name(key)))
        return 0xff
    cpdef handleEvent(self, object event):
        try:
            if (event.type == pygame.QUIT):
                self.quitFunc()
            elif (event.type == pygame.VIDEOEXPOSE):
                self.updateScreen(list())
            elif (event.type == pygame.KEYDOWN):
                (<PS2>self.main.platform.ps2).keySend(self.keyToScancode(event.key), False)
            elif (event.type == pygame.KEYUP):
                (<PS2>self.main.platform.ps2).keySend(self.keyToScancode(event.key), True)
            else:
                self.main.notice("PygameUI::handleEvent: event.type == {0:d}", event.type)
        except pygame.error:
            print(print_exc())
        except (SystemExit, KeyboardInterrupt):
            print(print_exc())
            self.main.quitEmu = True
            self.main.exitError('handleEvent: (SystemExit, KeyboardInterrupt) exception, exiting...)', exitNow=True)
        except:
            print(print_exc())
    cpdef updateScreen(self, list rectList):
        try:
            if (len(rectList) > 0):
                pygame.display.update(rectList)
            else:
                pygame.display.update()
        except pygame.error:
            print(print_exc())
        except (SystemExit, KeyboardInterrupt):
            print(print_exc())
            self.main.quitEmu = True
            self.main.exitError('updateScreen: (SystemExit, KeyboardInterrupt) exception, exiting...)', exitNow=True)
        except:
            print(print_exc())
    cpdef handleEvents(self):
        cpdef object event
        cpdef list eventList
        try:
            while (not self.main.quitEmu):
                event = pygame.event.wait()
                #eventList = pygame.event.get()
                #for event in eventList:
                self.handleEvent(event)
                #pygame.time.delay(200)
        except pygame.error:
            print(print_exc())
        except (SystemExit, KeyboardInterrupt):
            print(print_exc())
            self.main.quitEmu = True
            self.main.exitError('handleEvents: (SystemExit, KeyboardInterrupt) exception, exiting...)', exitNow=True)
        except:
            print(print_exc())
    cpdef pumpEvents(self):
        try:
            pygame.event.pump()
        except pygame.error:
            self.main.quitEmu = True
    cpdef run(self):
        self.initPygame()
        (<Misc>self.main.misc).createThread(self.handleEvents, True)


