package provide Display 1.0
package require Tcl     8.4

namespace eval ::Display {
  namespace export \
    display \
    verbose \
    debug \
    set_debug \
    set_verbose

  set debug   0
  set verbose 0
}

proc ::Display::display {msg} {
  puts $msg
}

proc ::Display::debug {msg} {
  global debug

  if {$Display::debug} {
    display "DEBUG: $msg"
  }
}

proc ::Display::error {msg} {
  display "ERROR: $msg"
  exit 1
}

proc ::Display::verbose {msg} {
  global verbose

  if {$Display::verbose} {
    display $msg
  }
}

proc ::Display::set_debug {newValue} {
  global debug

  set oldValue $Display::debug

  set Display::debug $newValue

  return $oldValue
}

proc ::Display::set_verbose {newValue} {
  global verbose

  set oldValue $Display::verbose

  set Display::verbose $newValue

  return $oldValue
}
