################################################################################
#
# File:         CVSAdm.pm
# Description:  Routines for generating portions of CVSAdm
# Author:       Andrew@DeFaria.com
# Created:      Fri Jul  8 12:35:48 PDT 2005
# Modified:
# Language:     Perl
#
# (c) Copyright 2005, LynuxWorks Inc., all rights reserved.
#
################################################################################
package CVSAdm;

use strict;
use CGI qw (:standard *table start_Tr end_Tr start_div end_div);
use Fcntl ':flock'; # import LOCK_* constants
use vars qw (@ISA @EXPORT);
use Exporter;

@ISA = qw (Exporter);

@EXPORT = qw (
  AddGroup
  AddSysUser
  AddUser
  CVSCommit
  CVSRepositories
  CVSServers
  CVSUpdate
  DeleteGroup
  DeleteSysUser
  DeleteUser
  DisplayError
  DisplayMsg
  Footing
  Groups
  Heading
  IsAdmin
  IsReader
  IsWriter
  PasswdEntry
  SystemUser
  SystemUsers
  UpdateGroup
  UpdateSysUser
  UpdateUser
  UserInGroup
  Users
);
# CVSAdm web app runs from a web server therefore it's running as an
# unprivileged user (usually the user apache) yet we want to maintain
# CVS user/group/sysuser information on CVS servers. As such we need a
# list of CVS servers to adminster. The $cvsadm_conf file describes the
# servers and repositories that we are allowed to manage. We will then
# rely on CVS itself to checkout the CVSROOT directory, modify the files
# appropriately then use CVS to commit these changes.
my $cvsadm_conf = "cvsadm.conf";

# These are the lists of special files that cvsadm managed under CVSROOT
# for cvsadm
my @cvsfiles = (
  "passwd",
  "groups",
  "sysusers",
  "readers",
  "writers"
);

my $heading_done = 0;

# Forwards
sub Add;
sub AddGroup;
sub AddSysUser;
sub AddUser;
sub CVSCommit;
sub CVSRepositories;
sub CVSServers;
sub CVSUpdate;
sub DeleteGroup;
sub DeleteSysUser;
sub DeleteUser;
sub DisplayError;
sub DisplayMsg;
sub Footing;
sub Groups;
sub Heading;
sub InFile;
sub IsAdmin;
sub IsReader;
sub IsWriter;
sub Lock;
sub Login;
sub OpenPasswd;
sub PasswdEntry;
sub Remove;
sub Read;
sub SystemUser;
sub SystemUsers;
sub Unlock;
sub UpdateAccess;
sub UpdateGroup;
sub UpdateSysUser;
sub UpdateUser;
sub UserInGroup;
sub Users;

sub Add {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $file		= shift;
  my $userid		= shift;

  my $filename = $file;
  $file = "$cvs_server/$repository/CVSROOT/$file";

  return if !-f $file;

  Lock $file;

  my @lines = Read $file;
  my $found = 0;

  foreach (@lines) {
    my $line = $_;
    chomp $line;

    $found = 1 if $line eq $userid;
  } # foreach

  push @lines, $userid . "\n" if !$found;

  my $euid = cookie "CVSAdmUser";
  my $commit_msg =
    $euid eq "cvsroot"		?
      "Adding $userid"		:
      "$euid added $userid";

  CVSCommit $cvs_server, $repository, $filename, $commit_msg, sort (@lines);

  Unlock $file;
} # Add

sub AddGroup {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $group		= shift;

  my $groups = "$cvs_server/$repository/CVSROOT/groups";

  Lock $groups;

  my @groups = Read $groups;

  foreach (@groups) {
    my $line = $_;
    chomp $line;
    return 1, "Group $group already exists" if $group eq $line;
  } # foreach

  push @groups, $group . "\n";

  my $euid = cookie "CVSAdmUser";
  my $commit_msg =
    $euid eq "cvsroot"		?
      "Added group $group"	:
      "$euid added group $group";

  CVSCommit $cvs_server, $repository, "groups", $commit_msg, sort (@groups);

  Unlock $groups;

  return 0, "Added group $group";
} # AddGroup

sub AddSysUser {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $sysuser		= shift;

  my $sysusers = "$cvs_server/$repository/CVSROOT/sysusers";

  Lock $sysusers;

  my @sysusers = Read $sysusers;

  foreach (@sysusers) {
    my $line = $_;
    chomp $line;
    return 1, "Sysuser $sysuser already exists" if $sysuser eq $line;
  } # foreach

  push @sysusers, $sysuser . "\n";

  CVSCommit $cvs_server, $repository, "sysusers", "Added sysuser $sysuser", sort (@sysusers);

  Unlock $sysusers;

  return 0, "Added sysuser $sysuser";
} # AddSysUser

sub AddUser {
  my $cvs_server	= shift;
  my $repository	= shift;
  my %user_record	= @_;

  # Check if userid already exists
  my %passwd = OpenPasswd $cvs_server, $repository;

  return 1,
    "Userid "			.
    $user_record {userid}	. 
    " already exists"
  if $passwd{$user_record {userid}};

  # Format passwd entry
  my %fields;
  $fields {password}	= crypt $user_record {password}, "xx";
  $fields {system_user}	= $user_record {system_user};
  $fields {fullname}	= $user_record {fullname};
  $fields {email}	= $user_record {email};

  # Handle groups (comma separated)
  my @groups = split /,/, $user_record {groups};
  $fields {groups}	= \@groups;

  $passwd {$user_record {userid}} = \%fields;

  my $passwd = "$cvs_server/$repository/CVSROOT/passwd";

  Lock $passwd;

  my @passwd;

  foreach (sort (keys %passwd)) {
    my %fields = %{$passwd {$_}};

    my $first_time = 1;
    my $group_str;

    foreach (@{$fields {groups}}) {
      if ($first_time) {
	$group_str = $_;
	$first_time = 0;
      } else {
	$group_str .= ",$_";
      } # if
    } # foreach

    my $passwd_line =
      $_			. ":" .
      $fields {password}	. ":" .
      $fields {system_user}	. ":" .
      $fields {fullname}	. ":" .
      $fields {email}		. ":" .
      $group_str		. "\n";

    push @passwd, $passwd_line;
  } # foreach

  my $euid = cookie "CVSAdmUser";
  my $commit_msg =
    $euid eq "cvsroot"				?
      "Added user " . $user_record {userid}	:
      "$euid added" . $user_record {userid};

  CVSCommit $cvs_server, $repository, "passwd", $commit_msg, sort (@passwd);

  Unlock $passwd;

  # Update readers and writers
  UpdateAccess $cvs_server, $repository, $user_record {userid}, $user_record {$repository};

  return 0, "Added user " . $user_record {userid};
} # AddUser

sub CVSCommit {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $filename		= shift;
  my $message		= shift;
  my @filedata		= @_;

  #my $logfile = "/tmp/commit.log";
  my $logfile = "/dev/null";

  my $CVSROOT = "$cvs_server/$repository/CVSROOT";
  my $cvsroot = ":pserver:cvsroot\@$cvs_server:/cvs/$repository";

  chdir $CVSROOT
    or DisplayError "Unable to chdir to $CVSROOT";

  open FILE, ">$filename"
    or DisplayError "Unable to open file $filename";

  foreach (@filedata) {
    print FILE $_;
  } # foreach

  close FILE;

  my $status = system "cvs -d $cvsroot commit -m \"$message\" $filename > $logfile 2>&1";

  DisplayError "Unable to commit $filename (Status: $status)" if $status ne 0;

  chdir "../../.."
    or DisplayError "Unable to chdir ../../..";
} # CVSCommit

sub CVSRepositories {
  my $cvs_server = shift;

  my %cvs_servers = CVSServers;

  return sort @{$cvs_servers {$cvs_server}};
} # CVSRepositories

sub CVSServers {
  my %cvs_servers;

  open CVSADM_CONF, $cvsadm_conf
    or DisplayError "Unable to open $cvsadm_conf - $!";

  my @lines = grep {!/^#/} <CVSADM_CONF>;

  foreach (@lines) {
    my ($server, $repository) = split;

    if (defined $cvs_servers {$server}) {
      my @repositories = @{$cvs_servers {$server}};
      push @{$cvs_servers {$server}}, $repository;
    } else {
      push @{$cvs_servers {$server}}, $repository;
    } # if
  } # foreach

  return %cvs_servers;
} # CVSServers

sub CVSUpdate {
  # Checkout or update @cvs_files in $cvs_server, $repository
  my $cvs_server	= shift;
  my $repository	= shift;

  my $status  = 0;
  my $CVSROOT = "$cvs_server/$repository/CVSROOT";
  my $cvsroot = ":pserver:$cvs_server:/cvs/$repository";

  my $logfile = "/tmp/checkout.log";
  `rm -f $logfile`;

  if (!-d $CVSROOT) {
    # Filestore for this repository does not exist. Create it and
    # check it out
    $status = system "mkdir -p $CVSROOT";

    DisplayError "Unable to create directory $CVSROOT (Status: $status)" if $status ne 0;

    chdir "$cvs_server/$repository"
      or DisplayError "Unable to chdir to $cvs_server/$repository";

    $status = system "cvs -d $cvsroot checkout CVSROOT > $logfile 2>&1";

    DisplayError "Unable to checkout $cvs_server/$repository/CVSROOT" if $status ne 0;

    chdir "../.."
      or DisplayError "Unable to chdir ../..";

    return 0;
  } # if

  chdir "$cvs_server/$repository"
    or DisplayError "Unable to chdir to $cvs_server/$repository";

  foreach (@cvsfiles) {
    # There may be no readers or writers files. Attempt to check them
    # out but allow failures to happen without increasing $status
    if ($_ eq "readers" or $_ eq "writers") {
      if (!-f "CVSROOT/$_") {
	system "cvs -d $cvsroot checkout CVSROOT/$_ >> $logfile 2>&1";
      } else {
	$status += system "cvs -d $cvsroot update CVSROOT/$_ >> $logfile 2>&1";
      } # if
    } else {
      $status += system "cvs -d $cvsroot checkout CVSROOT/$_ >> $logfile 2>&1";
    } # if
  } # foreach

  chdir "../.."
    or DisplayError "Unable to chdir ../..";

  return $status;
} # CVSUpdate

sub DeleteGroup {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $group		= shift;

  # Do not allow the cvsadm group to be deleted
  return 1, "You cannot delete the cvsadm group" if $group eq "cvsadm";

  my $groups = "$cvs_server/$repository/CVSROOT/groups";

  Lock $groups;

  my @groups = Read $groups;
  my @new_groups;

  foreach (@groups) {
    my $line = $_;
    chomp $line;

    next if $group eq $line;

    push @new_groups, "$line\n";
  } # foreach

  CVSCommit $cvs_server, $repository, "groups", "Removed group $group", sort (@new_groups);

  Unlock $groups;

  # Remove mention of this group from passwd file
  my $passwd = "$cvs_server/$repository/CVSROOT/passwd";

  Lock $passwd;

  my @lines = Read $passwd;
  my @new_lines;

  foreach (@lines) {
    my $line = $_;
    chomp $line;

    my @fields = split /:/, $line;

    if ($fields [5] !~ /$group/) {
      push @new_lines, "$line\n";
      next;
    } # if

    # Parse groups
    chomp $fields [5];
    my @old_groups = split /,/, $fields [5];
    @groups = ();

    foreach (@old_groups) {
      push @groups, $_ if $_ ne $group;
    } # foreach

    my $first_time = 1;
    my $group_str;

    foreach (@groups) {
      if ($first_time) {
	$group_str	= $_;
	$first_time	= 0;
      } else {
	$group_str     .= ",$_";
      } # if
    } # foreach

    my $passwd_line =
      $fields [0]	. ":" .
      $fields [1]	. ":" .
      $fields [2]	. ":" .
      $fields [3]	. ":" .
      $fields [4]	. ":" .
      $group_str	. "\n";

    push @new_lines, $passwd_line;
  } # foreach

  CVSCommit $cvs_server, $repository, "passwd", "Removed references to group $group from passwd", sort (@new_lines);

  Unlock $passwd;

  return 0, "Deleted group $group";
} # DeleteGroup

sub DeleteSysUser {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $sysuser		= shift;

  # Do not allow the cvsroot sysuser to be deleted
  return 1, "You cannot delete the cvsroot system user" if $sysuser eq "cvsroot";

  my $sysusers = "$cvs_server/$repository/CVSROOT/sysusers";

  Lock $sysusers;

  my @sysusers = Read $sysusers;
  my @new_sysusers;

  foreach (@sysusers) {
    my $line = $_;
    chomp $line;

    next if $sysuser eq $line;

    push @new_sysusers, "$line\n";
  } # foreach

  CVSCommit $cvs_server, $repository, "sysusers", "Removed sysuser $sysuser", sort (@new_sysusers);

  Unlock $sysusers;

  return 0, "Deleted system user $sysuser";
} # DeleteSysUser

sub DeleteUser {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $userid		= shift;

  # Do not allow the cvsroot user to be deleted
  return 1, "You cannot delete the cvsroot user" if $userid eq "cvsroot";

  my $passwd = "$cvs_server/$repository/CVSROOT/passwd";

  Lock $passwd;

  my @passwd = Read $passwd;
  my @new_passwd;

  foreach (@passwd) {
    my $line = $_;
    chomp $line;

    my @fields = split /:/, $line;

    next if $fields [0] eq $userid;

    push @new_passwd, "$line\n";
  } # foreach

  my $euid = cookie "CVSAdmUser";
  my $commit_msg =
    $euid eq "cvsroot"		?
      "Removed user $userid"	:
      "$euid removed user $userid";

  CVSCommit $cvs_server, $repository, "passwd", "Removed user $userid", sort (@new_passwd);

  Unlock $passwd;

  return 0, "Deleted user $userid";
} # DeleteUser

sub DisplayError {
  my $errmsg = shift;
  my $status = shift;

  if (!$heading_done) {
    # Put out a header so we can display the error message
    Heading (
      "",
      "",
      "CVSAdm: Error: $errmsg",
      "CVSAdm: Error: $errmsg",
    );
    $heading_done = 1;
  } # if

  print h3 ({-class => "error",
             -align => "center"}, "ERROR: " . $errmsg);

  if (!defined $status) {
    Footing;
    exit 1;
  } # if
} # DisplayError

sub DisplayMsg {
  my $msg = shift;

  print h3 ({-class => "msg",
             -align => "center"}, $msg);
} # DisplayMsg

sub Footing {
  my $table_name = shift;

  # General footing (copyright). Note we calculate the current year
  # so that the copyright automatically extends itself.
  my $year = substr ((scalar (localtime)), 20, 4);

  print start_div {-class => "copyright"};
  print "Copyright &copy; ", 
    a ({-href => "http://defaria.com"},
      "Andrew DeFaria"),
	" $year - All rights reserved";
  print end_div;

  print end_div; # This div ends "content" which was started in Heading
  print "<script language='JavaScript1.2'>AdjustTableWidth (\"$table_name\");</script>"
    if defined $table_name;
  print end_html;
} # Footing

sub Groups {
  my $cvs_server	= shift;
  my $repository	= shift;

  my $groups = "$cvs_server/$repository/CVSROOT/groups";

  my @lines = Read $groups;
  my @groups;

  foreach (@lines) {
    chomp;
    push @groups, $_;
  } # foreach

  return @groups;
} # Groups

sub Heading {
  # This subroutine puts out the header for web pages. It is called by
  # various cgi scripts thus has a few parameters.
  my $action            = shift; # One of getcookie, setcookie, unsetcookie
  my $userid            = shift; # User id (if setting a cookie)
  my $title             = shift; # Title string
  my $h1                = shift; # H1 header
  my $h2                = shift; # H2 header (optional)
  my $table_name        = shift; # Name of table in page, if any

  my @java_scripts;
  my $cookie;

  # Incorporate CVSAdmUtils.js
  push @java_scripts, [
    {-language  => "JavaScript1.2",
     -src       => "CVSAdmUtils.js"}];

  # Since Heading is called from various scripts we sometimes need to
  # set a cookie, other times delete a cookie but most times return the
  # cookie.
  if ($action eq "getcookie") {
    # Get userid from cookie
    $userid = cookie ("CVSAdmUser");
  } elsif ($action eq "setcookie") {
    $cookie = cookie (
       -name    => "CVSAdmUser",
       -value   => "$userid",
       -expires => "+1y",
       -path    => "/cvsadm"
    );
  } elsif ($action eq "unsetcookie") {
    $cookie = cookie (
       -name    => "CVSAdmUser",
       -value   => "",
       -expires => "-1d",
       -path    => "/cvsadm"
    );
  } # if

  print
    header     (-title  => "$title",
                -cookie => $cookie);

  if (defined $table_name) {
    print
      start_html (-title        => "$title",
                  -author       => "ADeFaria\@lnxw.com",
                  -style        => {-src        => "CVSAdmStyle.css"},
                  -onResize     => "AdjustTableWidth (\"$table_name\");",
                  -head         => [
                    Link ({-rel  => "icon",
                           -href => "http://wwww.lynuxworks.com/favicon.ico"})
                  ],
                  -script       => @java_scripts);
  } else {
    print
      start_html (-title        => "$title",
                  -author       => "ADeFaria\@lnxw.com",
                  -style        => {-src        => "CVSAdmStyle.css"},
                  -head         => [
                    Link ({-rel  => "icon",
                           -href => "http://wwww.lynuxworks.com/favicon.ico"})
		   ],
                  -script       => @java_scripts);
  } # if

  print start_div {class => "heading"};
#   if (defined $userid and $userid ne "") {
#     $h1 .= " (userid: $userid)";
#   } else {
#     $h1 .= " (userid: undefined)";
#   } # if

  print h2 {-align      => "center",
            -class      => "header"},
      $h1;

#   if ($action eq "setcookie") {
#     $h2 .= " - Set CVSAdmUser to $userid";
#   } elsif ($action eq "unsetcookie") {
#     $h2 .= " - Unset CVSAdmUser";
#   } else {
#     $h2 .= " - Action = $action";
#   } # if

  if (defined $h2 && $h2 ne "") {
    print h3 {-align    => "center",
              -class    => "header"},
      $h2;
  } # if
  print end_div;

  # Start body content
  print start_div {-class => "content"};

  $heading_done = 1;
  return $userid
} # Heading

### CVS Read/Write access ##############################################
# CVS decides read/write access based on the presence of the user name
# in the files readers and writers in the repository. Additionally
# either or both of these files may be missing.
#
# The CVS Manual says:
# 	If `readers' exists, and this user is listed in it, then she
# 	gets read-only access. Or if `writers' exists, and this user
# 	is NOT listed in it, then she also gets read-only access (this
# 	is true even if `readers' exists but she is not listed
# 	there). Otherwise, she gets full read-write access.
#
# 	Of course there is a conflict if the user is listed in both
# 	files. This is resolved in the more conservative way, it being
# 	better to protect the repository too much than too little:
# 	such a user gets read-only access.
#
# Based on that the following describe the access granted to a user.
#
# case	readers		writers		read access	write access
# ----	-----------	-----------	-----------	------------
#   1	No File		No File		    No		    No
#   2	No File		Not Present	    Yes		    No
#   3	No File		Present		    Yes		    Yes
#   4	Not Present	No File		    No		    No
#   5	Not Present	Not Present	    Yes		    No
#   6	Not Present	Present		    Yes		    Yes
#   7	Present		No File		    Yes		    No
#   8	Present		Not Present	    Yes		    No
#   9	Present		Present		    Yes		    No
#
# Case 1: A strict intepretation of the CVS manual might lead you to
# believe that since readers does not exist and writers does not exist
# then it would fall into the "Otherwise" statement at the end of the
# first paragraph. However an argument can be made that the user is
# also not listed in the writers file because the writers file is not
# present. But I believe that no access should be granted.
#
# Case 2: Readers does not exist and the user is not listed in writers
# so read only access.
#
# Case 3: Readers does not exist but the user is listed in writers. So
# the user has write access. Does this imply read access? Does
# write-only access exist?
#
# Case 4: User is not listed in the readers file and there is no writers
# file. This case is not covered by the CVS manual. My assumption is
# therefore no access. Again a strict interpretation might argue the
# "Otherwise" clause but I think not.
#
# Case 5: User is not listed in the readers file nor in the writers file
# therefore read only access.
#
# Case 6: User is not listed in the readers file but is listed in the
# writers file. User gets read/write access.
#
# Case 7: User is listed in the readers file but there is no writers
# file. Read only access.
#
# Case 8: User is listed in the readers file but not present in writers
# file. Read only access.
#
# Case 9: User is listed in the readers file and the writers file. This
# is the conflict. Resolve the conflict by only providing read access.
### CVS Read/Write access ##############################################
sub InFile {
  my $userid	= shift;
  my $file	= shift;

  return 0 if !-f $file;

  my @lines = Read $file;

  foreach (@lines) {
    my $line = $_;
    chomp $line;
    return 2 if $line eq $userid;
  } # foreach

  return 1;
} # InFile

sub IsAdmin {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $userid		= shift;

  return 0 if !defined $userid;
  return 1 if $userid eq "cvsroot";

  return UserInGroup ($cvs_server, $repository, $userid, "cvsadm");
} # IsAdmin

sub IsReader {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $userid		= shift;

  my $reader_status = InFile $userid, "$cvs_server/$repository/CVSROOT/readers";
  my $writer_status = InFile $userid, "$cvs_server/$repository/CVSROOT/writers";

  if ($reader_status eq 0) {
    # No reader file
    if ($writer_status eq 0) {
      # No writer file
      return 0; # Read access denied
    } elsif ($writer_status eq 1) {
      # Userid is not present in writers file
      return 1; # Read access granted
    } else {
      # Userid is present in writers file (implied read access)
      return 1; # Read access granted
    } # if
  } elsif ($reader_status eq 1) {
    # Userid is not in readers file
    if ($writer_status eq 0) {
      # No writer file
      return 0; # Read access denied
    } elsif ($writer_status eq 1) {
      # Userid is not present in writers file
      return 1; # Read access granted
    } else {
      # Userid is present in writers file (implied read access)
      return 1; # Read access granted
    } # if
  } else {
    # Userid is present in readers file
    if ($writer_status eq 0) {
      return 1; # Read access granted
    } elsif ($writer_status eq 1) {
      return 1; # Read access granted
    } else {
      return 1; # Read access granted
    } # if
  } # if
} # IsReader

sub IsWriter {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $userid		= shift;

  my $reader_status = InFile $userid, "$cvs_server/$repository/CVSROOT/readers";
  my $writer_status = InFile $userid, "$cvs_server/$repository/CVSROOT/writers";

  if ($reader_status eq 0) {
    # No reader file
    if ($writer_status eq 0) {
      # No writer file
      return 0; # Write access denied
    } elsif ($writer_status eq 1) {
      # Userid is not present in writers file
      return 0; # Write access denied
    } else { 
      # Userid is present in writers file
      return 1; # Write access granted
    } # if
  } elsif ($reader_status eq 1) {
    # Userid is not in readers file
    if ($writer_status eq 0) {
      # No writer file
      return 0; # Write access denied
    } elsif ($writer_status eq 1) {
      # Userid is not present in writers file
      return 0; # Write access denied
    } else {
      # Userid is present in writers file
      return 1; # Write access granted
    } # if
  } else {
    # Userid is present in readers file
    if ($writer_status eq 0) {
      return 0; # Write access denied
    } elsif ($writer_status eq 1) {
      return 0; # Write access denied
    } else {
      return 0; # Write access denied
    } # if
  } # if
} # IsWriter

sub Lock {
  my $file = shift;

  flock $file, LOCK_EX;
} # Lock

sub Login {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $username		= shift;
  my $password		= shift;

  my %passwd = OpenPasswd $cvs_server, $repository;

  if (!defined $passwd {$username}) {
    return 1;
  } # if

  my %fields = %{$passwd {$username}};

  my $salt = substr $fields {password}, 0, 2;

  $password = crypt $password, $salt;

  if ($fields {password} eq $password) {
    return 0;
  } else {
    return 2;
  } # if
} # Login

sub OpenPasswd {
  my $cvs_server	= shift;
  my $repository	= shift;

  my $passwd = "$cvs_server/$repository/CVSROOT/passwd";

  if (!-f $passwd) {
    # Passwd file is missing. Let's try a CVSUpdate...
    my $status = CVSUpdate $cvs_server, $repository;

    if ($status ne 0) {
      DisplayError "Unable to update CVSROOT! (Status: $status)";
    } # if
  } # if

  my %passwd;
  my @passwd = Read $passwd;

  foreach (@passwd) {
    my $line = $_;
    chomp $line;

    my @fields = split /:/, $line;

    my %fields;
    $fields {password}		= $fields [1];
    $fields {system_user}	= $fields [2];
    $fields {fullname}		= $fields [3];
    $fields {email}		= $fields [4];

    # Handle groups (comma separated)
    my @groups = split /,/, $fields [5];
    $fields {groups}		= \@groups;
    $passwd {$fields [0]}	= \%fields;
  } # foreach

  return %passwd;
} # OpenPasswd

sub PasswdEntry {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $userid		= shift;

  DisplayError "Userid not defined" if !defined $userid;

  my %passwd = OpenPasswd $cvs_server, $repository;

  if (!defined $userid or !defined $passwd {$userid}) {
    return undef;
  } else {
    return %{$passwd {$userid}};
  } # if
} # PasswdEntry

sub SystemUser {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $userid		= shift;

  my %passwd = OpenPasswd $cvs_server, $repository;

  my %fields = %{$passwd {$userid}};

  return $fields {system_user}
} # SystemUser

sub SystemUsers {
  my $cvs_server	= shift;
  my $repository	= shift;

  my $sysusers = "$cvs_server/$repository/CVSROOT/sysusers";

  my @lines = Read $sysusers;
  my @sysusers;

  foreach (@lines) {
    chomp;
    push @sysusers, $_;
  } # foreach

  return @sysusers;
} # SystemUsers

sub Unlock {
  my $file = shift;

  flock $file, LOCK_UN;
} # Unlock

sub Read {
  my $filename	= shift;

  open FILE, $filename
    or DisplayError "Unable to open file $filename - $!";

  my @lines = <FILE>;

  close FILE;

  return @lines;
} # Read

sub Remove {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $file		= shift;
  my $userid		= shift;

  my $filename = $file;
  $file = "$cvs_server/$repository/CVSROOT/$file";

  return if !-f $file;

  Lock $file;

  my @lines = Read $file;
  my @new_lines;

  foreach (@lines) {
    my $line = $_;
    chomp $line;

    next if $line eq $userid;

    push @new_lines, "$line\n";
  } # foreach

  my $euid = cookie "CVSAdmUser";
  my $commit_msg =
    $euid eq "cvsroot"		?
      "Removed $userid"		:
      "$euid removed $userid";

  CVSCommit $cvs_server, $repository, $filename, $commit_msg, sort (@new_lines);

  Unlock $file;
} # Remove

sub UpdateAccess {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $userid		= shift;
  my $access		= shift;

  if ($access eq "r") {
    Remove $cvs_server, $repository, "writers", $userid;
    Add    $cvs_server, $repository, "readers", $userid;
  } elsif ($access eq "rw") {
    Remove $cvs_server, $repository, "readers", $userid;
    Add    $cvs_server, $repository, "writers", $userid;
  } else {
    Remove $cvs_server, $repository, "readers", $userid;
    Remove $cvs_server, $repository, "writers", $userid;
  } # if
} # UpdateAccess

sub UpdateGroup {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $old_group		= shift;
  my $new_group		= shift;

  # CVS readers and writers files are a little weird. We will attempt
  # to simplify here. If a user has read only access to a repository
  # then we will explicitly list them in the readers file and make
  # sure they are not in the writers file. If they have write access
  # (thus implying read access) then we will arrange for them to be in
  # the writers file and absent from the readers file as CVS treats
  # users who are in both files as read only.
  my $groups = "$cvs_server/$repository/CVSROOT/groups";

  Lock $groups;

  my @groups = Read $groups;
  my @new_groups;

  foreach (@groups) {
    my $line = $_;
    chomp $line;

    if ($line eq $old_group) {
      push @new_groups, "$new_group\n";
    } else {
      push @new_groups, "$line\n";
    } # if
  } # foreach

  CVSCommit $cvs_server, $repository, "groups", "Changed $old_group -> $new_group in $groups", sort (@new_groups);

  Unlock $groups;

  my $passwd = "$cvs_server/$repository/CVSROOT/passwd";

  Lock $passwd;

  my @passwd = Read $passwd;
  my @new_passwd;

  foreach (@passwd) {
    my $line = $_;
    chomp $line;

    my @fields = split /:/, $line;
    my @groups = split /,/, $fields [5];

    my @new_groups;

    foreach (my $group = @groups) {
      chomp $group;

      if ($group eq $old_group) {
	push @new_groups, "$new_group\n";
      } else {
	push @new_groups, "$group\n";
      } # if
    } # foreach

    my $first_time = 1;
    my $group_str;

    foreach (@new_groups) {
      my $line = $_;
      chomp $line;

      if ($first_time) {
	$group_str = $line;
	$first_time = 0;
      } else {
	$group_str .= ",$line";
      } # if
    } # foreach

    my $passwd_line =
      $fields [0]	. ":" .
      $fields [1]	. ":" .
      $fields [2]	. ":" .
      $fields [3]	. ":" .
      $fields [4]	. ":" .
      $group_str	. "\n";

    push @new_passwd, $passwd_line;
  } # foreach

  CVSCommit $cvs_server, $repository, "passwd", "Updated $passwd changing any $old_group -> $new_group", sort (@new_passwd);

  Unlock $passwd;

  return 0;
} # UpdateGroup

sub UpdateSysUser {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $old_sysuser	= shift;
  my $new_sysuser	= shift;

  my $sysusers = "$cvs_server/$repository/CVSROOT/sysusers";

  Lock $sysusers;

  my @sysusers = Read $sysusers;
  my @new_sysusers;

  foreach (@sysusers) {
    my $line = $_;
    chomp $line;

    if ($old_sysuser eq $line) {
      push @new_sysusers, "$new_sysuser\n";
    } else {
      push @new_sysusers, "$line\n";
    } # if
  } # foreach

  CVSCommit $cvs_server, $repository, "sysusers", "Changed $old_sysuser -> $new_sysuser in $sysusers", sort (@new_sysusers);

  Unlock $sysusers;

  my $passwd = "$cvs_server/$repository/CVSROOT/passwd";

  Lock $passwd;

  my @passwd = Read $passwd;
  my @new_passwd;

  foreach (@passwd) {
    my $line = $_;
    chomp $line;

    my @fields = split /:/, $line;

    if ($fields [2] eq $old_sysuser) {
      $fields [2] = $new_sysuser;
    } # if

    my $passwd_line =
      $fields [0]	. ":" .
      $fields [1]	. ":" .
      $fields [2]	. ":" .
      $fields [3]	. ":" .
      $fields [4]	. ":" .
      $fields [5]	. "\n";

    push @new_passwd, $passwd_line;
  } # foreach

  CVSCommit $cvs_server, $repository, "passwd", "Updated $passwd changing any $old_sysuser -> $new_sysuser", sort (@new_passwd);

  Unlock $passwd;

  return 0;
} # UpdateSysUser

sub UpdateUser {
  my $cvs_server	= shift;
  my $repository	= shift;
  my %user_record	= @_;

  my $euid = cookie "CVSAdmUser";

  if (defined $user_record {new_password} and $user_record {new_password} ne "") {
    if (!IsAdmin $cvs_server, $repository, $euid) {
      my $status = CVSAdm::Login $cvs_server, $repository,
	$user_record {userid}, $user_record {old_password};
      if ($status ne 0) {
	DisplayError "The old password you supplied is invalid - Go back and try again";
	return 1;
      } # if
    } # if
  } # if

  UpdateAccess $cvs_server, $repository, $user_record {userid},  $user_record {$repository};

  my $passwd = "$cvs_server/$repository/CVSROOT/passwd";

  Lock $passwd;

  my @passwd = Read $passwd;
  my @new_passwd;

  foreach (@passwd) {
    my $line = $_;
    chomp $line;

    my @fields = split /:/, $line;

    if ($fields [0] eq $user_record {userid}) {
      if (defined $user_record {new_password} and $user_record {new_password} ne "") {
	my $salt = substr $fields [1], 0, 2;
	$user_record {password} = crypt $user_record {new_password}, $salt;
      } else {
	$user_record {password} = $fields [1];
      } # if

      $user_record {system_user} = $fields [2] if !defined $user_record {system_user};

      $line = $user_record {userid}		. ":" .
	      $user_record {password}		. ":" .
	      $user_record {system_user}	. ":" .
	      $user_record {fullname}		. ":" .
	      $user_record {email}		. ":" .
	      $user_record {groups};
    } # if

    push @new_passwd, "$line\n";
  } # foreach

  my $euid = cookie "CVSAdmUser";
  my $commit_msg =
    $euid eq "cvsroot"						?
      "Changed "       . $user_record {userid}	. " entry"	:
      "$euid changed " . $user_record {userid}	. " entry";

  CVSCommit $cvs_server, $repository, "passwd", $commit_msg, sort (@new_passwd);

  Unlock $passwd;

  return 0;
} # UpdateUser

sub UserInGroup {
  my $cvs_server	= shift;
  my $repository	= shift;
  my $userid		= shift;
  my $group		= shift;

  my %user_fields = PasswdEntry $cvs_server, $repository, $userid;

  return 0 if !defined $user_fields {groups};

  my @user_groups = @{$user_fields {groups}};

  foreach (@user_groups) {
    my $line = $_;
    chomp $line;

    return 1 if $group eq $line;
  } # foreach

  return 0;
} # UserInGroup

sub Users {
  my $cvs_server	= shift;
  my $repository	= shift;

  my @users;

  my %passwd = OpenPasswd $cvs_server, $repository;

  foreach (keys %passwd) {
    push @users, $_;
  } # foreach

  return sort @users;
} # Users

1;
