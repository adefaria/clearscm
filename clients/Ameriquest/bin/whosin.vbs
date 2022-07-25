On Error Resume Next

Set WshShell = WScript.CreateObject ("WScript.Shell")
Set fso      = CreateObject ("Scripting.FileSystemObject")

' Argument vector
Set ARGV = Wscript.Arguments

' Simple routine to shorten WScript.Echo!
Sub echo (msg)
  WScript.Echo msg
End Sub ' echo

Sub Display_Members (sendTo, groupname, members)
  echo "Members of the " & UCase (groupname) & " Group"

  previous_member = ""
  For Each member in members
    If member <> previous_member Then
      echo vbTAB & member
      previous_member = member
    End If
  Next
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

For Each ARG in ARGV
  Dim grp_mbrs ()

  ' Get members of this group
  DumpGroup (ARG)
  
  If UBound (grp_mbrs) > 0 Then
    ' Sort them
    QuickSort grp_mbrs, LBound (grp_mbrs), UBound (grp_mbrs)
    
    ' Output them
    Display_Members owner, ARG, grp_mbrs

    Erase grp_mbrs
    echo
  End If
Next