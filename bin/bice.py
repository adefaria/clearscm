#!/usr/bin/python

import sys
import getopt
import fcntl
import re

from array import *

security_logfile = '/var/log/auth.log'
verbose = False
debug   = False
update  = False
email   = False

def Error (msg = '', errno = 0):
  sys.stderr.write ('Error: ' + msg)

  if (errno <> 0):  
    sys.exit (errno)

def Verbose (msg, linefeed = True):
  global verbose
  
  if (linefeed):
    msg += '\n'
    
  if (verbose):
    print msg

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
  
  sys.exit (1)

def processLogfile (logfile):
  violations = {}
    
  try:
    readlog = open (logfile)

    fcntl.flock (readlog, fcntl.LOCK_EX)
  except IOError:
    Error ("Unable to get exclusive access to " + logfile + " - $!", 1)
    
  invalid_user           = re.compile ("^(\S+\s+\S+\s+\S+)\s+.*Invalid user (\w+) from (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})")
  authentication_failure = re.compile ("^(\S+\s+\S+\s+\S+)\s+.*authentication failure.*ruser=(\S+).*rhost=(\S+)")
  failed_password        = re.compile ("^(\S+\s+\S+\s+\S+)\s+.*Failed password for (\w+) from (\d{1,3}\.\d{1,3}\.d{1,3}\.d{1,3})")
  
  for newline in readlog:
    violation = {}
    newline = newline.strip ()
    
    timestamp = ''
    user      = ''
    ip        = ''
    
    for (timestamp, user, ip) in invalid_user.findall (newline):
      continue
      
    for (timestamp, user, ip) in authentication_failure.findall (newline):
      continue
      
    for (timestamp, user, ip) in failed_password.findall (newline):
      continue
     
    if (ip == ''):
      continue
      
    if (ip in violations):
      violation = violations[ip]

    if (user in violation):
      violation[user].append (timestamp)
    else:
      violation[user] = [];
      violation[user].append (timestamp)
    
    violations[ip] = violation
    
  return violations

def ReportBreakins (logfile):
  violations = processLogfile (logfile)
  
  nbrViolations = len (violations)
  
  if (nbrViolations == 0):
    Verbose ('No violations found')
  elif (nbrViolations == 1):
    Verbose ('1 site attempting to violate our perimeter')
  else:
    Verbose ('{} violations'.format(nbrViolations))

  for ip in violations:
    print 'IP: ' + ip + ' violations:'
    for key in sorted (violations[ip].iterkeys ()):
      print "\t{}: {}".format (key, violations[ip][key])
                    
def dumpargs ():
  global verbose, debug, update, email, security_logfile

  print 'Args:'
  print 'verbose', verbose
  print 'debug',   debug
  print 'update',  update
  print 'email',   email
  print 'file',    security_logfile

def main (argv):
  global verbose, debug, update, email, security_logfile
  
  try:
    opts, args = getopt.getopt (argv, "vd", ['verbose', 'debug', 'usage', 'update', 'mail', 'file='])
  except getopt.GetoptError:
    Usage ();
    sys.exit (1);

  for opt, arg in opts:
    if opt in ['-v', '--verbose']:
      verbose = 1
    elif opt in ['-d', '--debug']:
      debug = 1
    elif opt in ['-u', '--usage']:
      Usage 
    elif opt in ['--update']:
      update = 1
    elif opt in ['-m', '--mail']:
      email = 1
    elif opt in ['-f', '--file']:
      security_logfile = arg
  
  if security_logfile == '':
    Usage ('Must specify filename')
    
  ReportBreakins (security_logfile)
#  dumpargs ()
  
if __name__ == '__main__':
  main (sys.argv [1:])