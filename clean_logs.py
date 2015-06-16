#!/usr/bin/env python3.4

import re, os, sys, time

class Clea:
    def __init__(self):
        self.fn1 = self.fn2 = self.fn3 = ''
        self.fp3 = None
        self.checkArgs()
    def checkArgs(self):
        if (len(sys.argv) != 4):
            print("Usage: clean_logs.py <f1> <f2> <f3>")
            sys.exit(1)
            return
        self.fn1 = sys.argv[1]
        self.fn2 = sys.argv[2]
        self.fn3 = sys.argv[3]
    def loopFunc(self):
        p = None
        cmdline = "diff --speed-large-files {0:s} {1:s} > {2:s}".format(self.fn1, self.fn2, self.fn3)
        #print(cmdline)
        #sys.stdout.flush()
        os.system(cmdline)
        self.fp3 = open(self.fn3, "rt")
        for i in range(1000):
            l = self.fp3.readline().rstrip()
            m = re.match(r"(\d+)a(\d+),(\d+)", l)
            if (m):
                #a1 = int(m.group(2))-3
                #a2 = int(m.group(3))-3
                a1 = ((int(m.group(2))//10)*10)+2
                a2 = ((int(m.group(3))//10)*10)+1
            else:
                #print("ERROR: m doesn't match!")
                #sys.exit()
                if (l[0] in ("<", ">", "-")):
                    continue
                m = re.match(r"(\d+),(\d+)c(\d+),(\d+)", l)
                if (not m):
                    m = re.match(r"(\d+)c(\d+)", l)
                    #if (not m):
                    #    m1 = re.match(r"(\d+),(\d+)c(\d+)", l)
                if (m):
                    a1 = ((int(m.group(1))//10)*10)+2
                    p = os.popen("grep -n 0028:c0001444 {0:s}".format(self.fn2))
                    while (True):
                        a2 = int(p.readline().rstrip().split(":")[0])+1
                        if (a2 >= a1 or a2 >= a1+1):
                            break
                #elif (m1):
                elif (0):
                    p = os.popen("grep -n 0028:c0001100 {0:s}".format(self.fn2))
                    a1 = int(p.readline().rstrip().split(":")[0])+2
                    p = os.popen("grep -n 0028:c0001444 {0:s}".format(self.fn2))
                    while (True):
                        a2 = int(p.readline().rstrip().split(":")[0])+1
                        if (a2 >= a1 or a2 >= a1+1):
                            break
                else:
                    continue
            if ((a1%2)!=0 or (a2%1)!=0):
                print("ERROR: line numbers aren't correct!")
                sys.exit()
            cmdline = "cp {0:s} {0:s}.orig ; sed '{1:d},{2:d}d' {0:s}.orig > {0:s}".format(self.fn2, a1, a2)
            print(cmdline)
            sys.stdout.flush()
            time.sleep(3)
            print("Run")
            os.system(cmdline)
            break
        self.fp3.close()
    def doLoops(self, loops=1):
        for i in range(loops):
            self.loopFunc()
    def run(self):
        sys.stdout.write("\n"*5)
        sys.stdout.flush()
        self.doLoops(20000)
        #self.doLoops(100)
        #self.doLoops(1)



if (__name__ == '__main__'):
    clea = Clea()
    clea.run()



