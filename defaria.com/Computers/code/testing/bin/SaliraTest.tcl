namespace eval Test {
  # Test: This module contains the testing scaffolding necessary to implement
  #       testing in a consistant and easy manner.

  # Functions & Variables
  namespace export	\
    CLI			\
    Debug		\
    Display		\
    End			\
    EndSuite		\
    Error		\
    Failed		\
    Log			\
    Login		\
    LoginVxWorks	\
    Passed		\
    Start		\
    StartSuite		\
    Verbose		\
    Warning		\
    failure		\
    reason		\
    salira_prompt	\
    status		\
    success		\
    succeeded		\
    test_name

  # Variables useful for testing
  variable status		0
  variable salira_prompt	"\# "
  variable success		$salira_prompt
  variable succeeded		"succeeded"
  variable reason		""
  variable failure		"Error"
  variable total_tests_run
  variable total_tests_passed
  variable total_tests_failed
  variable test_name		""
  variable leaveopen

  # Internal state variables
  variable verbose
  variable debug
  variable test_base	"/dview/defaria_default/Tools/testing"
  variable logfile
  variable connection
  variable depth
  variable machine	"172.16.35.211"

  # Globals
  global spawn_id

  # Reporting procedures
  proc Error {args} {
    variable status

    send_user "ERROR: [join $args]\n"
    set status 1
    exit 1;
  }

  proc Warning {args} {
    send_user "WARNING: [join $args]\n"
  }

  proc Verbose {args} {
    variable verbose

    if {[info exist verbose]} {
      send_user "[join $args]\n"
    }
  }

  proc Debug {args} {
    variable debug

    if {[info exist debug]} {
      send_user "DEBUG: [join $args]\n"
    }
  }

  proc Display {args} {
    send_user "[join $args]\n"
  }

  # Logging routines
  proc Log {args} {
    variable logfile

    Verbose [join $args]
    puts $logfile [join $args]
    flush $logfile
  }

  proc Passed {args} {
    variable total_tests_passed
    variable test_name

    if {[info exist total_tests_passed]} {
      incr total_tests_passed
    } else {
      set total_tests_passed 1
    }

    Log "Test PASSED: $test_name [join $args]"
  }

  proc Failed {args} {
    variable total_tests_failed
    variable test_name

    if {[info exist total_tests_failed]} {
      incr total_tests_failed
    } else {
      set total_tests_failed 1
    }

    Log "Test FAILED: $test_name [join $args]"
  }

  # Login routines
  proc Login {machine {username root} {password root}} {
    global spawn_id

    variable connection
    variable test_base
    variable logfile
    variable depth

    # Turn off logging
    log_user 0

    # Check to see if we are already connected
    if {[info exist connection]} {
      # Already connected
      return $connection
    }

    # Establish connection
    spawn "telnet" $machine
    set connection $spawn_id

    Debug "Logging into $machine..."

    # Look for Login prompt
    expect {
      "Login:" {
      }
      timeout {
        Error "$machine is not responding"
      }
    }

    send $username\r
    expect {
      "Password:" {
        send $password\r
      }
      timeout {
        Error "Password prompt not issued"
      }
    }

    expect {
      "\# " {
        Debug "Logged into $machine"
      }
      timeout {
        Error "$machine appears to be dead"
      }
    }

    if {![info exist depth]} {
      set depth 1
    } else {
      incr depth
    }

    return $connection
  }

  proc Logout {} {
    variable depth
    variable leaveopen

    if {[info exist leaveopen] && $leaveopen == 1} {
      return
    }

    for {set i 0} {$i < $depth} {incr i} {
      send "logout\r"
    }
  }
				 
  proc LoginVxWorks {{username root} {password root}} {
    Debug "Logging into VxWorks console..."

    send "cc 1\r"

    expect {
      "login: " {
        # Success
      }
      default {
        Error "Fatal error: Unable to switch to VxWorks console"
	exit 1
      }
    }

    # Due to a bug we need to hit return one more time
    send \r

    expect {
      "login: " {
        # Success
      }
      default {
        Error "Fatal error: Unable to switch to VxWorks console"
	exit 1
      }
    }

    # OK now we are read to login
    send $username\r

    expect {
      "Password:" {
        # Success
      }
      default {
        Error "Fatal error: VxWorks did not issue a password prompt!"
	exit 1
      }
    }

    send $password\r

    expect {
      -gl "-\> " {
        # Success
      }
      default {
        Error "Fatal error: Unable to switch to VxWorks console"
	exit
      }
    }

    if {![info exist depth]} {
      set depth 1
    } else {
      incr depth
    }

    Debug "Logged into VxWorks console"
  }

  proc StartSuite {} {
    variable test_base
    variable logfile
    variable leaveopen

    # Start logfile
    set leaveopen 1

    set date_n_time	[clock format [clock seconds] -format "%m-%d-%Y-%H-%M"]
    set logfilename	"$test_base/results/testrun-$date_n_time.log"
    set logfile		[open $logfilename w]

    Log ">>>\tStart test run [clock format [clock seconds]]"
  }

  proc Start {{name} {to_machine $Test::machine}} {
    variable logfile
    variable machine
    variable reason
    variable result
    variable test_base
    variable test_name
    variable total_tests_run

    global spawn_id

    set test_name $name
    set machine $to_machine
    set result 0
    set reason ""

    # For individual test attempt to Login. Note if StartSuite was
    # called then we will already be connected so Login will simply
    # return
    Login $machine

    # $logfile will be already opened if StartSuite was called. If not
    # then we are running a single test so open a logfile per test case
    if {[info exists logfile] == 0} {
      set scriptname [string range [info script] 0 \
		       [expr [string last "." [info script]] - 1]]
      set logfilename	"$scriptname.log"
      set logfile	[open $logfilename w]
    }

    Log ">\tStart test $test_name [clock format [clock seconds]]"

    if {[info exists total_tests_run]} {
      incr total_tests_run
    } else {
      set total_tests_run 1
    }

    return $spawn_id
  }

  proc End {} {
    variable result
    variable reason
    variable test_name

    if {$result == 0} {
      Passed $reason
    } else {
      Failed $reason
    }

    Log ">\tEnd test $test_name [clock format [clock seconds]]"
	  
    Logout
  }

  proc EndSuite {} {
    variable total_tests_run
    variable total_tests_passed
    variable total_tests_failed

    # Set to zero any undefined variables
    if {![info exist total_tests_run]} {
      set total_tests_run 0
    }
    if {![info exist total_tests_passed]} {
      set total_tests_passed 0
    } 
    if {![info exist total_tests_failed]} {
      set total_tests_failed 0
    } 
      
    Log ">>>\tEnd test run [clock format [clock seconds]]"
    Log "========================="
    Log "Tests run:\t$total_tests_run"
    Log "Tests passed:\t$total_tests_passed"
    Log "Tests failed:\t$total_tests_failed"
    Log "========================="

    set leaveopen 0
    Logout
  }

  proc CLI {cmd {success ""}} {
    if {$success == ""} {
      set success $Test::salira_prompt
    }

    send "$cmd\r"

    expect {
      $success {
        return
      } "Error: Bad command" {
        set Test::result 1
        Log "Bad command $cmd encountered"
	End
      } timeout {
        set Test::result 1
	Log "Unable to execute $cmd - expecting $success"
        End
      }
    }
  }
}
