sub display (msg) 
  wscript.echo msg
end sub

host = "."

set wmi      = GetObject     ("winmgmts:\\" & host & "\root\cimv2")
set packages = wmi.ExecQuery ("Select * from Win32_Product",, 48)

for each package in packages
  display "Name:        " & package.Name
  display "Version:     " & package.Version
  display "Vendor:      " & package.Vendor
  display "Description: " & package.Description
  display "-------------------------------------------------------------------------------"
next