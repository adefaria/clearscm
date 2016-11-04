#!/usr/bin/python

import sys, getopt

security_logfile = '/var/log/auth.log'
verbose = 0
debug   = 0
update  = 0
email   = 0

def Usage (msg = ''):
  if msg != '':
    print msg
    
  print """
Usage: bice.py [-u|sage] [-v|erbose] [-d|ebug] [-nou|pdate] [-nom|ail]
               [-f|ilename <filename> ]

Where:
  -u|sage     Print this usage
  -v|erbose:  Verbose mode (Default: -verbose)
  -nou|pdate: Don't update security logfile file (Default: -update)
  -nom|ail:   Don't send emails (Default: -mail)
  -f|ilename: Open alternate messages file (Default: /var/log/auth.log)
  """
def mainold (argv):
  global verbose, debug, update, email, security_logfile
  
  print "in main"
  
  try:
    #opts, args = getopt.getopt (argv, "vd", ['verbose', 'debug', 'usage', 'update', 'mail', 'file='])
    opts, args = getopt.getopt (argv, "hi:o:", ["ifile=","ofile="])
  except getopt.GetoptError:
    Usage;
    sys.exit (1);
    
  for opt, arg in opts:
    print 'opt: ', opt
    print 'arg:',  arg
     
    if opt in ['-v', '-verbose']:
      verbose = 1
    elif opt in ['-d', '-debug']:
      debug = 1
    elif opt in ['-u', '-usage']:
      Usage 
    elif opt in ['-update']:
      update = 1
    elif opt in ['-m', '-mail']:
      email = 1
    elif opt in ['-f', '-file']:
      security_logfile = arg
  
  print 'Args:'
  print 'verbose', verbose
  print 'debug',   debug
  print 'update',  update
  print 'email',   email
  print 'file',    security_logfile
  
def main(argv):
  global verbose, debug, update, email, security_logfile

  inputfile = ''
  outputfile = ''

  try:
    opts, args = getopt.getopt(argv,"hvi:o:",["verbose", "ifile=","ofile="])
  except getopt.GetoptError:
    Usage ()
    print 'test.py -i <inputfile> -o <outputfile>'
    sys.exit(2)
    
  for opt, arg in opts:
    print 'opt: ', opt
    print 'arg: ', arg
    if opt in ['-v', '--verbose']:
      verbose = 1
    elif opt in ['-u', '-usage']:
      Usage ()
    elif opt == '-h':
      print 'test.py -i <inputfile> -o <outputfile>'
      sys.exit()
    elif opt in ("-i", "--ifile"):
      inputfile = arg
    elif opt in ("-o", "--ofile"):
      outputfile = arg

  print 'Args:'
  print 'verbose', verbose
  print 'debug',   debug
  print 'update',  update
  print 'email',   email
  print 'file',    security_logfile

if __name__ == "__main__":
   main (sys.argv[1:])