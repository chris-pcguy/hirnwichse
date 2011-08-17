import misc, curses, atexit, sys, os

class cursesUI:
    def __init__(self, main):
        self.main = main
        self.screen, self.window = None, None
        #os.linesep='\r\n'
        #sys.stdout.newline=None
        #sys.stderr.newline=None
    def quitFunc(self):
        curses.endwin()
        if (self.screen):
            self.screen.keypad(0)
        curses.nocbreak()
        curses.echo()
    def putChar(self, y, x, char):
        try:
            self.window.addch(y, x, char)
        except curses.error:
            pass
    def run(self):
        atexit.register(self.quitFunc)
        self.screen = curses.initscr()
        curses.noecho()
        curses.cbreak()
        self.screen.keypad(1)
        self.screen.clear()
        self.screen.refresh()
        self.window = curses.newwin(25, 80, 0, 0)
        self.window.noutrefresh()
        self.screen.refresh()

