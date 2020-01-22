import os
import sys
import argparse
'''

    James M. Ferguson (j.ferguson@garvan.org.au)
    Genomic Technologies
    Garvan Institute
    Copyright 2019

    script description

    ----------------------------------------------------------------------------
    version 0.0 - initial



    TODO:
        -

    ----------------------------------------------------------------------------
    MIT License

    Copyright (c) 2019 James Ferguson

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
'''


class MyParser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)


def main():
    '''
    do the thing
    '''
    parser = MyParser(
        description="script name - script description")
    #group = parser.add_mutually_exclusive_group()
    parser.add_argument("-f", "--fastq",
                        help="merged fastq file")
    parser.add_argument("-s", "--seq_sum",
                        help="merged fastq file")

    args = parser.parse_args()

    # print help if no arguments given
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    dic, files = get_pairs(args.seq_sum)
    process_fastq(args.fastq, dic, files)




def get_pairs(ss):
    '''
    read seq sum and get fq file names with ID
    '''
    dic = {}
    head = True
    files = []
    with open(ss, 'r') as f:
        for l in f:
            if head:
                head = False
                continue
            l = l.strip('\n')
            l = l.split('\t')
            file = l[0].split('.')[:-1] + ".fastq"
            dic[l[1]] = file
            if file not in files:
                files.append(file)
    return dic, files

def process_fastq(fq, dic, files):
    D = False
    c = 0
    P_dic = {}
    for w in files:
        P_dic[w] = open(w, 'w')
    with open(fq, 'r') as f:
        for l in f:
            c += 1
            if c == 1:
                r = l.split(' ')[0][1:]
                if r in dic:
                    D = True
                    P = P_dic[dic[r]]
                    P.write(l)
            elif c < 4:
                if D:
                    P.write(l)
            elif c == 4:
                if D:
                    P.write(l)
                c = 0
                D = False


if __name__ == '__main__':
    main()
