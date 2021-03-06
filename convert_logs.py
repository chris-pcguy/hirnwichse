#!/usr/bin/env python3.6

import re, sys

class Comp:
    def __init__(self):
        self.fn1 = self.fn2 = ''
        self.fp1 = self.fp2 = self.rfp1 = self.rfp2 = None
        self.checkArgs()
    def checkArgs(self):
        if (len(sys.argv) != 3):
            print("Usage: convert_logs.py <bochs log f1> <hirnwichse log f2>")
            sys.exit(1)
            return
        self.fn1 = sys.argv[1]
        self.fn2 = sys.argv[2]
    def parse_f1(self):
        r = r2 = r3 = ''
        skip_first_lines = True
        l = []
        self.fp1 = open(self.fn1, 'rt')
        self.rfp1 = open('converted_1', 'wt')
        while True:
            i = self.fp1.readline()
            if (not i):
                break
            if (skip_first_lines):
                if (i.find('eax') != -1):
                    skip_first_lines = False
                else:
                    continue
            m = re.search(r'\] ([0-9a-f]{4}):([0-9a-f]{4,8}) \(', i)
            if (m):
                r3 = r2
                r2 = r = '{0:s}:{1:s}\n'.format(m.group(1), m.group(2).rjust(8, '0'))
                #self.rfp1.write(r)
                l.append(r)
                if (r3 != r2):
                    self.rfp1.writelines(l)
                l = []
            m = re.search(r'(e\w{2}|eflags)(:? )(0x[0-9a-f]{8})', i)
            if (m):
                n = m.group(1).upper()
                if (n not in ('EIP', 'ESS')):
                    r = '{0:s}: {1:s}\n'.format(n, m.group(3))
                    #self.rfp1.write(r)
                    l.append(r)
        self.rfp1.flush()
        self.rfp1.close()
    def parse_f2(self):
        skip_first_lines = True
        self.fp2 = open(self.fn2, 'rt')
        self.rfp2 = open('converted_2', 'wt')
        s = ''
        while True:
            i = self.fp2.readline()
            if (not i):
                break
            if (skip_first_lines):
                if (i.find('Current Opcode') != -1):
                    skip_first_lines = False
                else:
                    continue
            m = re.search(r'EIP: 0x([0-9a-f]{4,8}), CS: 0x([0-9a-f]{4})', i)
            if (m):
                s = '{0:s}:{1:s}\n'.format(m.group(2), m.group(1).rjust(8, '0'))
                #self.rfp2.write(r)
            if (i.find('NOTICE: E') == 0 and i.find(': 0x') != -1 and i.find(', ') != -1):
                i = i[8:].rstrip()
                j = i.split(', ')
                for k in j:
                    m = re.search(r'(E\w{2}|EFLAGS): (0x[0-9a-f]{8})', k)
                    if (m):
                        n = m.group(1).upper()
                        if (n != 'EIP'):
                            r = '{0:s}: {1:s}\n'.format(n, m.group(2))
                            self.rfp2.write(r)
                        if (n == 'EFLAGS'):
                            self.rfp2.write(s)
        self.rfp2.flush()
        self.rfp2.close()
    def run(self):
        self.parse_f1()
        self.parse_f2()



if (__name__ == '__main__'):
    comp = Comp()
    comp.run()



