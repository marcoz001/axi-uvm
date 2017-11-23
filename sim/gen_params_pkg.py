#!/usr/bin/env python

# this script just generates a constrained-random params_pkg.sv
# every possiblecombinationtobeattheeverlivinghell out of the dut

import sys
import os
import random
import argparse

valid_addr_widths = [32,64];
valid_data_widths = [8,16,32,64,128,256,512,1024];
valid_len_widths  = [4,8];
valid_id_widths   = [4,5];

# the random way
naddr = random.choice(valid_addr_widths);
ndata = random.choice(valid_data_widths);
nlen  = random.choice(valid_len_widths);
nid   = random.choice(valid_id_widths);



parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--template', dest='template',
                    help='Template for params_pkg.sv')
parser.add_argument('--outputdir', dest='outputdir', default=".",
                    help='Directory for output files')


args = parser.parse_args()

if (args.template is None):
  print("Missing argument temlate")
  parser.print_help()
  sys.exit(1)


# exists and is readable
if not os.path.isfile(args.template):
  print("%s isn't a file or does not exist." % args.template)
  sys.exit(1)

if not os.access(args.template, os.R_OK):
  print("file %s isnt' readable." % args.template)
  sys.exit(1)


if not os.path.exists(args.outputdir):
  print("director %s does not exist. Creating"%args.outputdir)
  os.mkdir( args.outputdir, 0755 );

if not os.path.isdir(args.outputdir):
  print("'%s' isn't a directory." % args.outputdir)
  sys.exit(1)

if not os.access(args.outputdir, os.W_OK):
  print("directory %s isn't writable." % args.outputdir)
  sys.exit(1)
  

#rfile = open("params_pkg.sv_TMPL", "r")
rfile = open(args.template, "r")
#wfile = open("FOO.sv", "w")
#wfile.write(rfile.read())
#wfile.close()

rfilecontents=rfile.read()

#print(rfilecontents)
# the brute force way
for addr in valid_addr_widths:
   afile=rfilecontents.replace("<ADDR_WIDTH>", str(addr))
   for data in valid_data_widths:
      dfile=afile.replace("<DATA_WIDTH>", str(data))
      for len in valid_len_widths:
         lfile=dfile.replace("<LEN_WIDTH>", str(len))
         for id in valid_id_widths:
            ifile=lfile.replace("<ID_WIDTH>", str(id))
            wfilename=("%s/params_pkg_id-%0d_addr-%0d_data-%0d_len-%0d.sv" % (args.outputdir,id,addr,data,len))
            print("Filename: %s"% wfilename)
            wfile = open(wfilename, "w")
            wfile.write(ifile)
            wfile.close()
   


#'Hello world'.replace('world', 'Guido')

#import argparse

#parser = argparse.ArgumentParser(description='Process some integers.')
#parser.add_argument('integers', metavar='N', type=int, nargs='+',
                    #help='an integer for the accumulator')
#parser.add_argument('--sum', dest='accumulate', action='store_const',
                    #const=sum, default=max,
                    #help='sum the integers (default: find the max)')
#
#args = parser.parse_args()
#print(args.accumulate(args.integers))


