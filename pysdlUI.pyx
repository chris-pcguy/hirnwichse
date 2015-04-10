
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"

from sys import exit
from traceback import print_exc
from atexit import register
import numpy
import sdl2, sdl2.ext
import ctypes


#DEF EVENT_LIST = ( sdl2.SDL_ACTIVEEVENT, sdl2.SDL_MOUSEMOTION, sdl2.SDL_MOUSEBUTTONDOWN, sdl2.SDL_MOUSEBUTTONUP,\
#                   sdl2.SDL_JOYAXISMOTION, sdl2.SDL_JOYBALLMOTION, sdl2.SDL_JOYHATMOTION, sdl2.SDL_JOYBUTTONDOWN,\
#                   sdl2.SDL_JOYBUTTONUP, sdl2.SDL_VIDEORESIZE, sdl2.SDL_USEREVENT )

cdef tuple EVENT_LIST = ( sdl2.SDL_MOUSEMOTION, sdl2.SDL_MOUSEBUTTONDOWN, sdl2.SDL_MOUSEBUTTONUP,\
                   sdl2.SDL_JOYAXISMOTION, sdl2.SDL_JOYBALLMOTION, sdl2.SDL_JOYHATMOTION, sdl2.SDL_JOYBUTTONDOWN,\
                   sdl2.SDL_JOYBUTTONUP, sdl2.SDL_USEREVENT )


cdef class PysdlUI:
    def __init__(self, Vga vga):
        self.vga  = vga
        self.window = self.screen = self.renderer = None
        self.replicate8Bit = self.mode9Bit = self.msbBlink = True
        self.screenSize = 720, 480
        self.charSize = (9, 16)
        self.fontDataA = b'\x00'*VGA_FONTAREA_SIZE
        self.fontDataB = b'\x00'*VGA_FONTAREA_SIZE
    cpdef initPysdl(self):
        cdef unsigned short event
        sdl2.SDL_Init(sdl2.SDL_INIT_TIMER | sdl2.SDL_INIT_VIDEO | sdl2.SDL_INIT_EVENTS)
        sdl2.SDL_SetHintWithPriority(sdl2.SDL_HINT_RENDER_DRIVER, b"opengl", sdl2.SDL_HINT_OVERRIDE)
        self.window = sdl2.ext.Window('Hirnwichse', self.screenSize, flags=sdl2.SDL_WINDOW_SHOWN)
        self.screen = self.window.get_surface()
        self.renderer = sdl2.ext.Renderer(self.screen)
        register(self.quitFunc)
        for event in EVENT_LIST:
            sdl2.SDL_EventState(event, sdl2.SDL_IGNORE)
        self.setRepeatRate(500, 10)
    cpdef quitFunc(self):
        try:
            self.vga.main.quitFunc()
            sdl2.SDL_Quit()
        except:
            print_exc()
            self.vga.main.exitError('quitFunc: exception, exiting...')
    cpdef clearScreen(self):
        pass
        #self.screen.fill((0, 0, 0))
    cpdef object getCharRect(self, unsigned short x, unsigned short y):
        cpdef object r
        try:
            r = sdl2.rect.SDL_Rect()
            r.x, r.y = (self.charSize[0]*x, self.charSize[1]*y)
            r.w, r.h = self.charSize
            return r
        except:
            print_exc()
            self.vga.main.exitError('getCharRect: exception, exiting...')
        return None
    cpdef object getBlankChar(self, unsigned int bgColor):
        cpdef object blankSurface
        blankSurface = sdl2.surface.SDL_CreateRGBSurface(0, self.charSize[0], self.charSize[1], 32, 0xFF000000, 0x00FF0000, 0x0000FF00, 0x00000000).contents
        sdl2.surface.SDL_FillRect(blankSurface, None, bgColor)
        return blankSurface
    cpdef object putPixel(self, unsigned short x, unsigned short y, unsigned char colors): # returns rect
        cpdef object newRect, colorObject
        cdef unsigned int bgColor
        try:
            #newRect = sdl2.rect.SDL_Rect(x, y, 1, 1)
            #newRect = sdl2.rect.SDL_Rect(x<<1, y<<1, 2, 2)
            # bgColor == RGBA; colors == (A?)RGB
            if (self.msbBlink):
                colors &= 0x7
            bgColor = self.vga.getColor(colors)
            colorObject = sdl2.ext.RGBA(bgColor)
            #sdl2.surface.SDL_FillRect(self.newPixel, None, bgColor)
            if (self.renderer):
                #sdl2.SDL_BlitScaled(self.newPixel, None, self.screen, newRect)
                self.renderer.draw_point((x, y), colorObject)
                #self.renderer.fill(((x*self.vga.charHeight, y, self.vga.charHeight, 1),), colorObject)
            #return newRect
        except:
            print_exc()
            self.vga.main.exitError('putPixel: exception, exiting...')
        return None
    cpdef object putChar(self, unsigned short x, unsigned short y, unsigned char character, unsigned char colors): # returns rect
        cpdef object newRect, newChar, charArray
        cdef bytes charData
        cdef unsigned int i, j, k, fgColor, bgColor
        try:
            newRect = self.getCharRect(x, y)
            fgColor = self.vga.getColor(colors&0xf)
            bgColor = self.vga.getColor((colors>>4)&0x7 if (self.msbBlink) else (colors>>4))
            newChar = self.getBlankChar(bgColor)
            # It's not a good idea to render a character if fgColor == bgColor
            #   as it wouldn't be readable.
            if (fgColor != bgColor): # TODO
                charArray = sdl2.ext.pixels2d(newChar)
                i = character*VGA_FONTAREA_CHAR_HEIGHT
                if (colors & 8):
                    charData = self.fontDataA[i:i+self.charSize[1]]
                else:
                    charData = self.fontDataB[i:i+self.charSize[1]]
                for i in range(len(charData)):
                    j = charData[i]
                    if (self.mode9Bit):
                        j <<= 1
                        if (self.replicate8Bit and (character&0xe0==0xc0)):
                            j |= (j&2)>>1
                    k = 0
                    while (j):
                        if (j & (0x100 if (self.mode9Bit) else 0x80)):
                            charArray[k][i] = fgColor
                        k += 1
                        j <<= 1
                        j &= 0x1ff if (self.mode9Bit) else 0xff
            if (self.screen):
                sdl2.SDL_BlitScaled(newChar, None, self.screen, newRect)
            return newRect
        except:
            print_exc()
            self.vga.main.exitError('putChar: exception, exiting...')
        return None
    cpdef setRepeatRate(self, unsigned short delay, unsigned short interval):
        pass
        #pygame.key.set_repeat(delay, interval)
    cdef unsigned char keyToScancode(self, unsigned int key):
        self.vga.main.notice("keyToScancode: test1: keyToScancode. (keyId: {0:d}, keyName: {1:s})", key, repr(sdl2.keyboard.SDL_GetKeyName(sdl2.keyboard.SDL_GetKeyFromScancode(key))))
        if (key == sdl2.SDL_SCANCODE_LCTRL):
            return 0x00
        elif (key == sdl2.SDL_SCANCODE_LSHIFT):
            return 0x01
        elif (key == sdl2.SDL_SCANCODE_F1):
            return 0x02
        elif (key == sdl2.SDL_SCANCODE_F2):
            return 0x03
        elif (key == sdl2.SDL_SCANCODE_F3):
            return 0x04
        elif (key == sdl2.SDL_SCANCODE_F4):
            return 0x05
        elif (key == sdl2.SDL_SCANCODE_F5):
            return 0x06
        elif (key == sdl2.SDL_SCANCODE_F6):
            return 0x07
        elif (key == sdl2.SDL_SCANCODE_F7):
            return 0x08
        elif (key == sdl2.SDL_SCANCODE_F8):
            return 0x09
        elif (key == sdl2.SDL_SCANCODE_F9):
            return 0x0a
        elif (key == sdl2.SDL_SCANCODE_F10):
            return 0x0b
        elif (key == sdl2.SDL_SCANCODE_F11):
            return 0x0c
        elif (key == sdl2.SDL_SCANCODE_F12):
            return 0x0d
        elif (key == sdl2.SDL_SCANCODE_RCTRL):
            return 0x0e
        elif (key == sdl2.SDL_SCANCODE_RSHIFT):
            return 0x0f
        elif (key == sdl2.SDL_SCANCODE_CAPSLOCK):
            return 0x10
        elif (key == sdl2.SDL_SCANCODE_NUMLOCKCLEAR):
            return 0x11
        elif (key == sdl2.SDL_SCANCODE_LALT):
            return 0x12
        elif (key == sdl2.SDL_SCANCODE_RALT):
            return 0x13
        elif (key == sdl2.SDL_SCANCODE_A):
            return 0x14
        elif (key == sdl2.SDL_SCANCODE_B):
            return 0x15
        elif (key == sdl2.SDL_SCANCODE_C):
            return 0x16
        elif (key == sdl2.SDL_SCANCODE_D):
            return 0x17
        elif (key == sdl2.SDL_SCANCODE_E):
            return 0x18
        elif (key == sdl2.SDL_SCANCODE_F):
            return 0x19
        elif (key == sdl2.SDL_SCANCODE_G):
            return 0x1a
        elif (key == sdl2.SDL_SCANCODE_H):
            return 0x1b
        elif (key == sdl2.SDL_SCANCODE_I):
            return 0x1c
        elif (key == sdl2.SDL_SCANCODE_J):
            return 0x1d
        elif (key == sdl2.SDL_SCANCODE_K):
            return 0x1e
        elif (key == sdl2.SDL_SCANCODE_L):
            return 0x1f
        elif (key == sdl2.SDL_SCANCODE_M):
            return 0x20
        elif (key == sdl2.SDL_SCANCODE_N):
            return 0x21
        elif (key == sdl2.SDL_SCANCODE_O):
            return 0x22
        elif (key == sdl2.SDL_SCANCODE_P):
            return 0x23
        elif (key == sdl2.SDL_SCANCODE_Q):
            return 0x24
        elif (key == sdl2.SDL_SCANCODE_R):
            return 0x25
        elif (key == sdl2.SDL_SCANCODE_S):
            return 0x26
        elif (key == sdl2.SDL_SCANCODE_T):
            return 0x27
        elif (key == sdl2.SDL_SCANCODE_U):
            return 0x28
        elif (key == sdl2.SDL_SCANCODE_V):
            return 0x29
        elif (key == sdl2.SDL_SCANCODE_W):
            return 0x2a
        elif (key == sdl2.SDL_SCANCODE_X):
            return 0x2b
        elif (key == sdl2.SDL_SCANCODE_Y):
            return 0x2c
        elif (key == sdl2.SDL_SCANCODE_Z):
            return 0x2d
        elif (key == sdl2.SDL_SCANCODE_0):
            return 0x2e
        elif (key == sdl2.SDL_SCANCODE_1):
            return 0x2f
        elif (key == sdl2.SDL_SCANCODE_2):
            return 0x30
        elif (key == sdl2.SDL_SCANCODE_3):
            return 0x31
        elif (key == sdl2.SDL_SCANCODE_4):
            return 0x32
        elif (key == sdl2.SDL_SCANCODE_5):
            return 0x33
        elif (key == sdl2.SDL_SCANCODE_6):
            return 0x34
        elif (key == sdl2.SDL_SCANCODE_7):
            return 0x35
        elif (key == sdl2.SDL_SCANCODE_8):
            return 0x36
        elif (key == sdl2.SDL_SCANCODE_9):
            return 0x37
        elif (key == sdl2.SDL_SCANCODE_ESCAPE):
            return 0x38
        elif (key == sdl2.SDL_SCANCODE_SPACE):
            return 0x39
        elif (key == sdl2.SDL_SCANCODE_APOSTROPHE):
            return 0x3a
        elif (key == sdl2.SDL_SCANCODE_COMMA):
            return 0x3b
        elif (key == sdl2.SDL_SCANCODE_PERIOD):
            return 0x3c
        elif (key == sdl2.SDL_SCANCODE_SLASH):
            return 0x3d
        elif (key == sdl2.SDL_SCANCODE_SEMICOLON):
            return 0x3e
        elif (key == sdl2.SDL_SCANCODE_EQUALS):
            return 0x3f
        elif (key == sdl2.SDL_SCANCODE_LEFTBRACKET):
            return 0x40
        elif (key == sdl2.SDL_SCANCODE_NONUSBACKSLASH):
            return 0x41
        elif (key == sdl2.SDL_SCANCODE_RIGHTBRACKET):
            return 0x42
        elif (key == sdl2.SDL_SCANCODE_MINUS):
            return 0x43
        elif (key == sdl2.SDL_SCANCODE_GRAVE):
            return 0x44
        elif (key == sdl2.SDL_SCANCODE_BACKSPACE):
            return 0x45
        elif (key == sdl2.SDL_SCANCODE_RETURN):
            return 0x46
        elif (key == sdl2.SDL_SCANCODE_TAB):
            return 0x47
        #elif (key == sdl2.SDL_SCANCODE_BACKSLASH): # left backslash??
        #    return 0x48
        elif (key == sdl2.SDL_SCANCODE_PRINTSCREEN):
            return 0x49
        elif (key == sdl2.SDL_SCANCODE_SCROLLLOCK):
            return 0x4a
        elif (key == sdl2.SDL_SCANCODE_PAUSE):
            return 0x4b
        elif (key == sdl2.SDL_SCANCODE_INSERT):
            return 0x4c
        elif (key == sdl2.SDL_SCANCODE_DELETE):
            return 0x4d
        elif (key == sdl2.SDL_SCANCODE_HOME):
            return 0x4e
        elif (key == sdl2.SDL_SCANCODE_END):
            return 0x4f
        elif (key == sdl2.SDL_SCANCODE_PAGEUP):
            return 0x50
        elif (key == sdl2.SDL_SCANCODE_PAGEDOWN):
            return 0x51
        elif (key == sdl2.SDL_SCANCODE_KP_PLUS):
            return 0x52
        elif (key == sdl2.SDL_SCANCODE_KP_MINUS):
            return 0x53
        #elif (key == sdl2.SDL_SCANCODE_KP_END):
        #    return 0x54
        #elif (key == sdl2.SDL_SCANCODE_KP_DOWN):
        #    return 0x55
        #elif (key == sdl2.SDL_SCANCODE_KP_PAGEDOWN):
        #    return 0x56
        #elif (key == sdl2.SDL_SCANCODE_KP_LEFT):
        #    return 0x57
        #elif (key == sdl2.SDL_SCANCODE_KP_RIGHT):
        #    return 0x58
        #elif (key == sdl2.SDL_SCANCODE_KP_HOME):
        #    return 0x59
        #elif (key == sdl2.SDL_SCANCODE_KP_UP):
        #    return 0x5a
        #elif (key == sdl2.SDL_SCANCODE_KP_PAGEUP):
        #    return 0x5b
        #elif (key == sdl2.SDL_SCANCODE_KP_INSERT):
        #    return 0x5c
        #elif (key == sdl2.SDL_SCANCODE_KP_DELETE):
        #    return 0x5d
        elif (key == sdl2.SDL_SCANCODE_KP_5):
            return 0x5e
        elif (key == sdl2.SDL_SCANCODE_UP):
            return 0x5f
        elif (key == sdl2.SDL_SCANCODE_DOWN):
            return 0x60
        elif (key == sdl2.SDL_SCANCODE_LEFT):
            return 0x61
        elif (key == sdl2.SDL_SCANCODE_RIGHT):
            return 0x62
        elif (key == sdl2.SDL_SCANCODE_KP_ENTER):
            return 0x63
        elif (key == sdl2.SDL_SCANCODE_KP_MULTIPLY):
            return 0x64
        elif (key == sdl2.SDL_SCANCODE_KP_DIVIDE):
            return 0x65
        elif (key == sdl2.SDL_SCANCODE_LGUI):
            return 0x66
        elif (key == sdl2.SDL_SCANCODE_APPLICATION):
            return 0x67
        elif (key == sdl2.SDL_SCANCODE_MENU):
            return 0x68
        elif (key == sdl2.SDL_SCANCODE_SYSREQ): # OR SYSRQ?
            return 0x69
        #elif (key == sdl2.SDL_SCANCODE_BREAK):
        #    return 0x6a
        self.vga.main.notice("keyToScancode: unknown key. (keyId: {0:d}, keyName: {1:s})", key, repr(sdl2.keyboard.SDL_GetKeyName(sdl2.keyboard.SDL_GetKeyFromScancode(key))))
        return 0xff
    cpdef handleSingleEvent(self, object event):
        if (event.type == sdl2.SDL_QUIT):
            self.quitFunc()
            exit(1)
        #elif (event.type == sdl2.SDL_VIDEOEXPOSE):
        elif (event.type == 512): # 512 == sdl2.SDL_VIDEOEXPOSE ?
            self.updateScreen()
        elif (event.type == sdl2.SDL_KEYDOWN):
            if (event.key.keysym.scancode == sdl2.SDL_SCANCODE_KP_MINUS):
                self.vga.main.debugEnabled = not self.vga.main.debugEnabled
                return
            elif (event.key.keysym.scancode == sdl2.SDL_SCANCODE_KP_PLUS):
                self.vga.refreshScreen = True
                return
            (<PS2>self.vga.main.platform.ps2).keySend(self.keyToScancode(event.key.keysym.scancode), False)
        elif (event.type == sdl2.SDL_KEYUP):
            if (event.key.keysym.scancode == sdl2.SDL_SCANCODE_KP_MINUS):
                return
            elif (event.key.keysym.scancode == sdl2.SDL_SCANCODE_KP_PLUS):
                return
            (<PS2>self.vga.main.platform.ps2).keySend(self.keyToScancode(event.key.keysym.scancode), True)
        else:
            self.vga.main.notice("PysdlUI::handleSingleEvent: event.type == {0:d}", event.type)
    cpdef updateScreen(self):
        if (self.window and self.screen):
            self.window.refresh()
    cpdef handleEventsWithoutWaiting(self):
        cpdef object event
        try:
            for event in sdl2.ext.get_events():
                self.handleSingleEvent(event)
                #sdl2.timer.SDL_Delay(200)
        except (SystemExit, KeyboardInterrupt):
            self.quitFunc()
        except:
            print_exc()
            self.vga.main.exitError('handleEvents: exception, exiting...')
    cpdef handleEvents(self):
        cpdef object event
        event = sdl2.SDL_Event()
        try:
            while (not self.vga.main.quitEmu):
                sdl2.SDL_WaitEvent(ctypes.byref(event))
                self.handleSingleEvent(event)
                #sdl2.timer.SDL_Delay(200)
        except (SystemExit, KeyboardInterrupt):
            self.quitFunc()
        except:
            print_exc()
            self.vga.main.exitError('handleEvents: exception, exiting...')
    cpdef run(self):
        try:
            self.initPysdl()
            #self.handleEvents()
            #(<Misc>self.vga.main.misc).createThread(self.handleEvents, True)
        except:
            print_exc()
            self.vga.main.exitError('run: exception, exiting...')


