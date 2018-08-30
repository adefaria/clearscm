#########################################################################
#
# File:         Display.py
# Description:  Display module
#
#########################################################################
import sys, os
from libxml2mod import xmlXPathNewValueTree

if os.getenv('DEBUG') != None:
  DEBUG = True
else:
  DEBUG = False

if os.getenv('VERBOSE') != None:
  VERBOSE = True
else:
  VERBOSE = False

def caller_name():
    frame=inspect.currentframe()
    frame=frame.f_back.f_back
    code=frame.f_code
    return code.co_filename

def display(msg = '', handle = sys.stdout, nolinefeed = False):
  handle.write(msg)
  
  if nolinefeed == False:
    handle.write("\n")

def display_err(msg, handle = sys.stderr, nolinefeed = False):

  handle.write(msg)

  if nolinefeed == False:
    handle.write("\n") 

def debug(msg, handle = sys.stderr, nolinefeed = False, level = 0):
  global DEBUG

  if DEBUG == False:
    return

  display_err('DEBUG: ' + msg, handle, nolinefeed)

def error(msg, errno = 0, handle = sys.stderr, nolinefeed = False):
  display_err('ERROR: {0}'.format(msg), handle, nolinefeed)

  if errno != 0:
    sys.exit(errno) 

def warning(msg, warnno = 0, handle = sys.stderr, nolinefeed = False):
   display_err('WARNING:' + msg, handle, nolinefeed)

def verbose(msg, handle = sys.stdout):
  global VERBOSE

  if VERBOSE == False:
    return

  display(msg, handle)

def set_verbose(newValue):
  global VERBOSE
  
  oldValue = VERBOSE

  VERBOSE = newValue

  return oldValue

def set_debug(newValue):
  global DEBUG
  
  oldValue = DEBUG

  DEBUG = newValue

  return oldValue