import misc, pygame, threading, atexit, sys, time, _thread

cdef class pygameUI:
    cdef object main, vga, display, screen, font
    cdef tuple size, fontSize
    cdef unsigned short width, height, fontWidth, fontHeight
    def __init__(self, object vga, object main):
        self.vga  = vga
        self.main = main
        self.display, self.screen, self.font = None, None, None
        self.size = self.width, self.height = 640, 400
        self.fontSize = self.fontWidth, self.fontHeight = self.width//80, self.height//25
        pygame.display.init()
        pygame.font.init()
        pygame.display.set_caption("ChEmu - THE x86 Emulator written in Python. (c) 2011 by Christian Inci")
        self.display = pygame.display.set_mode(self.size)
        self.screen = pygame.Surface(self.size)
        self.font = pygame.font.SysFont( 'VeraMono',  self.fontHeight)
        atexit.register(self.quitFunc)
    def quitFunc(self):
        try:
            pygame.font.quit()
            pygame.display.quit()
        except pygame.error:
            print(sys.exc_info())
        except:
            print(sys.exc_info())
        ###_thread.exit()
        self.main.quitFunc()
    def getCharRect(self, unsigned char x, unsigned char y):
        try:
            return pygame.Rect((self.fontWidth*x, self.fontHeight*y), self.fontSize)
        except pygame.error:
            print(sys.exc_info())
            return
        except:
            print(sys.exc_info())
            return
    def getColor(self, unsigned char color):
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
    def getBlankChar(self, tuple bgColor):
        cdef object blankSurface
        blankSurface = pygame.Surface(self.fontSize)
        blankSurface.fill(bgColor)
        return blankSurface
    def putChar(self, unsigned char x, unsigned char y, str char, unsigned char colors): # returns rect
        cdef object newRect, newChar, newBack
        cdef tuple fgColor, bgColor
        try:
            newRect = self.getCharRect(x, y)
            fgColor, bgColor = self.getColor(colors&0xf), self.getColor((colors&0xf0)>>4)
            newBack = self.getBlankChar(bgColor)
            if (char.isprintable()):
                newChar = self.font.render(char, False, fgColor, bgColor)
                newBack.blit(newChar, ( (0, 0), self.fontSize ))
            self.screen.blit(newBack, newRect)
            return newRect
        except pygame.error:
            print(sys.exc_info())
            _thread.exit()
            return
        except:
            print(sys.exc_info())
            _thread.exit()
            return
    def handleEvent(self, object event):
        try:
            if (event.type == pygame.QUIT):
                self.quitFunc()
            elif (event.type == pygame.VIDEOEXPOSE):
                self.updateScreen()
        except pygame.error:
            print(sys.exc_info())
            _thread.exit()
        except:
            print(sys.exc_info())
            _thread.exit()
    def updateScreen(self, object rectList=None):
        try:
            if (self.display and self.screen and not self.main.quitEmu):
                self.display.blit(self.screen, (0, 0))
            pygame.display.update(rectList)
        except pygame.error:
            print(sys.exc_info())
            _thread.exit()
        except:
            print(sys.exc_info())
            _thread.exit()
    def handleThread(self):
        try:
            while (not self.main.quitEmu):
                event = pygame.event.wait()
                #for event in pygame.event.get():
                self.handleEvent(event)
                #    #time.sleep(0.05)
                #    time.sleep(1)
            self.quitFunc()
        except pygame.error:
            print(sys.exc_info())
            _thread.exit()
        except:
            print(sys.exc_info())
            _thread.exit()
    

    
