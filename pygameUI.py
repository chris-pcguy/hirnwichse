import misc, pygame, threading, atexit, sys, _thread

class pygameUI:
    def __init__(self, vga, main):
        self.vga  = vga
        self.main = main
        self.display, self.screen, self.font = None, None, None
        self.size = self.width, self.height = 640, 400
        self.fontSize = self.fontWidth, self.fontHeight = self.width//80, self.height//25
    def quitFunc(self):
        self.main.quitFunc()
        pygame.font.quit()
        pygame.display.quit()
        _thread.exit()
    def getCharRect(self, x, y):
        return pygame.Rect((self.fontWidth*x, self.fontHeight*y), self.fontSize)
    def getColor(self, color):
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
    def putChar(self, x, y, char, colors): # returns rect
        newRect = self.getCharRect(x, y)
        fgColor, bgColor = colors&0xf, (colors&0xf0)>>4
        fgColor, bgColor = self.getColor(fgColor), self.getColor(bgColor)
        if (not char.isprintable()):
            char = ' '
        newChar = self.font.render(char, True, fgColor, bgColor)
        self.screen.blit(newChar, newRect)
        return newRect
    def handleEvent(self, event):
        if (event.type == pygame.QUIT):
            self.main.quitFunc()
    def updateScreen(self, rectList=None):
        if (self.display and self.screen):
            self.display.blit(self.screen, (0, 0))
        pygame.display.update(rectList)
    def handleThread(self):
        try:
            while (not self.main.quitEmu):
                #for event in pygame.event.get():
                event = pygame.event.wait()
                self.handleEvent(event)
            self.quitFunc()
        except:
            print(sys.exc_info())
            _thread.exit()
    def run(self):
        try:
            pygame.display.init()
            pygame.font.init()
            self.display = pygame.display.set_mode(self.size)
            self.screen = pygame.Surface(self.size)
            self.font = pygame.font.SysFont( 'VeraMono',  self.fontHeight)
            atexit.register(self.quitFunc)
        except:
            print(sys.exc_info())
            _thread.exit()

