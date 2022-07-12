On Error Resume Next

Set WshShell = WScript.CreateObject ("WScript.Shell")
Set fso      = CreateObject ("Scripting.FileSystemObject")

groups_file = "\\rtnlprod02\viewstore\PMO\CM_TOOLS\etc\groups.dat"

' Simple routine to shorten WScript.Echo!
Sub echo (msg)
  WScript.Echo msg
End Sub ' echo

Sub Email_Owner (sendTo, groupname, members)
  sch = "http://schemas.microsoft.com/cdo/configuration/"

  Set cdoConfig = CreateObject ("CDO.Configuration")

  With cdoConfig.Fields
    .Item (sch & "sendusing")   = 2 ' cdoSendUsingPort
    .Item (sch & "smtpserver")  = "appsmtp.ameriquest.net"
    .Update
  End With

  Set email_msg = CreateObject ("CDO.Message")

  email_msg.Configuration       = cdoConfig
  email_msg.From                = "PMO-CM@Ameriquest.net"
  email_msg.To                  = sendTo
  email_msg.Subject             = "Members of the " & UCase (groupname) & " Group"
  email_msg.HTMLBody            = "<h3>Members of the " & UCase (groupname) & " Group</h3><p>&nbsp;</p><ol>"

  previous_member = ""
  For Each member in members
    If member <> previous_member Then
      email_msg.HTMLBody = email_msg.HTMLBody & "<li>" & member & "</li>"
      previous_member = member
    End If
  Next

  email_msg.HTMLBody = email_msg.HTMLBody & "</ol>"
  email_msg.Send
End Sub  

' Routine to push things onto an array
Sub pushArray (a, e)
  On Error Resume Next
  size = UBound (a)

  If Err.Number <> 0 Then
    size = 0
  Else
    size = size + 1
  End If
  
  ReDim preserve a (size)

  a (UBound (a)) = e
End Sub 'pushArray

' The famous QuickSort!
Sub QuickSort (vec, loBound, hiBound)
  Dim pivot
  Dim loSwap
  Dim hiSwap
  Dim temp

  ' This procedure is adapted from the algorithm given in:
  '    Data Abstractions & Structures using C++ by
  '    Mark Headington and David Riley, pg. 586
  ' Quicksort is the fastest array sorting routine for
  ' unordered arrays.  Its big O is  n log n

  ' Two items to sort
  If hiBound - loBound = 1 Then
    If vec(loBound) > vec(hiBound) Then
      temp          = vec (loBound)
      vec (loBound) = vec (hiBound)
      vec (hiBound) = temp
    End If
  End If

  ' Three or more items to sort
  pivot                               = vec (Int ((loBound + hiBound) / 2))
  vec (Int ((loBound + hiBound) / 2)) = vec (loBound)
  vec (loBound)                       = pivot
  loSwap                              = loBound + 1
  hiSwap                              = hiBound
  
  Do
    ' Find the right loSwap
    While loSwap < hiSwap and vec (loSwap) <= pivot
      loSwap = loSwap + 1
    Wend
    
    ' Find the right hiSwap
    While vec (hiSwap) > pivot
      hiSwap = hiSwap - 1
    Wend
    
    ' Swap values if loSwap is less then hiSwap
    If loSwap < hiSwap Then
      temp         = vec (loSwap)
      vec (loSwap) = vec (hiSwap)
      vec (hiSwap) = temp
    End If
  Loop While loSwap < hiSwap
  
  vec (loBound) = vec(hiSwap)
  vec (hiSwap)  = pivot
  
  ' Recursively call function .. the beauty of Quicksort
    ' 2 or more items in first section
  If loBound < (hiSwap - 1) Then
    QuickSort vec, loBound, hiSwap - 1
  End If
  
  ' 2 or more items in second section
  If hiSwap + 1 < hibound Then
    QuickSort vec, hiSwap+1, hiBound
  End If
End Sub ' QuickSort

' Get the group members out of Active Directory and push them
' onto the grp_mbrs array
Sub DumpGroup (groupname)
  ' Create an LDAP object and set up the search for groupname
  On Error Resume Next
  Err.Clear
  Set LDAPGroups = GetObject (                            _
    "LDAP://cn="                                        & _
    groupname                                           & _ 
    ",ou=apps,ou=Groups,ou=Corp,dc=ameriquest,dc=net"     _
  )
  
  If Err.Number <> 0 Then
    Err.Clear
    echo "Warning: " & UCase (groupname) & " is empty!"
    Exit Sub
  End If

  LDAPGroups.GetInfo

  ' Get an array of members
  members = LDAPGroups.GetEx ("member")

  ' For each member get their displayName and push it onto the array
  For Each member in members
    Set user = GetObject ("LDAP://"& member)
    LDAPGroups.filter = array ("user")
    user.GetInfo

    ' Kludgy way to check to see if this is a group: We attempt
    ' to get groupType which should only be in a group type 
    ' record. If this fails then process the member as an
    ' individual member, otherwise recurse to process the
    ' group within the group...
    Err.Clear
    user.Get ("groupType")

    if Err.Number = 0 Then
      Err.Clear
      groupname = LCase (user.Get ("cn"))
      DumpGroup (groupname)
    Else
      name = user.Get ("displayName")
      pushArray grp_mbrs, name
    End If
  Next
End Sub  

' Open the groups definition file
Set groups = fso.OpenTextFile (groups_file)

Do While Not groups.AtEndOfStream
  line = groups.ReadLine

  ' *** Need to also skip blank lines
  If Line <> "" Then
    If InStr (line, "#") <> 1 Then
      With New RegExp
        .Pattern = "\s+"
        .Global = True
        line = Trim (.replace (line, " "))
      End With

      ' Split out fields
      groupname = ""
      owner     = ""
      fields = Split (line)
      groupname = LCase (fields (0))
      owner     = LCase (fields (1))

      echo "Processing group " & UCase (groupname) & " (" & owner & ")"

      Dim grp_mbrs ()

      ' Get members of this group
      DumpGroup (groupname)

      If UBound (grp_mbrs) > 0 Then
        ' Sort them
        QuickSort grp_mbrs, LBound (grp_mbrs), UBound (grp_mbrs)

        ' Output them
        If owner <> "" Then
          Email_Owner owner, groupname, grp_mbrs
        Else
          echo "Group: " & UCase (groupname) & " has no owner email in " & groups_file
        End If

        Erase grp_mbrs
      End If
    End If
  End If
Loop
