option explicit

sub display (msg) 
  wscript.echo msg
end sub

sub checkError (msg)
  if err.number = 0 then
    exit sub
  end if

  display "Error " & err.number & ": " & msg

  if err.description <> "" then
    display err.description
  end if

  wscript.quit err.number
end sub

dim net, server, service, enumerator, instance, loadavg, locator, namespace

' Get localhost's name
set net = CreateObject ("Wscript.Network")
server  = net.ComputerName

set locator = CreateObject ("WbemScripting.SWbemLocator")

checkError "Unable to create locator object"

' Connect to the namespace which is either local or remote
set service = locator.ConnectServer (server, namespace, "", "")

checkError "Unable to connect to server " & server

service.Security_.impersonationlevel = 3

set enumerator = service.InstancesOf ("Win32_Processor")

checkError "Unable to query Win32_Processor"

loadavg = 0

for each instance in enumerator
  if not (instance is nothing) then
    if instance.LoadPercentage <> "" then
      loadavg = loadavg + instance.LoadPercentage
    end if
  end if   
next

display loadavg
