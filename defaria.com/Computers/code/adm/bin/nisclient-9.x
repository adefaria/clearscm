#!/bin/bash
###############################################################################
# This script sets a machine up to be an NIS client.
# Kevin Lister 10.28.98

###############################################################################
# Variables
logfile=/nisclient.log
me=${0##*/}

admin=cll-support@cup.hp.com
nisdomain=cll
domainname=
netnfsrc=/etc/netnfsrc
nsswitch=/etc/nsswitch.conf
pwfile=/etc/passwd
lclpwfile=/etc/passwd.loc
nispwfile=/etc/passwd.nis
crontab=/usr/spool/cron/crontabs/root
newcrontab=/tmp/root-crontab
null=/dev/null
ypdir=/usr/etc/yp

# Functions
function error {
  print -u2 "$me: Error: $1"
  /usr/bin/mailx -s "$(uname -n): NIS setup error: $1" $admin < $null
  exit 255;
} # error

function warning {
  print -u2 "$me: Warning: $1"
} # warning

function display {
  print "$1"
} # display

function info {
  display "$me: Info: $1"
} # info

##
########## Main
##

##
########## Check the status of the system before proceeding
##

# Must be root to run this
if [ $(id -u) -ne 0 ]; then
        error "Must be root to execute this command... Exiting."
fi

# Check to see if this script has already been ran
if [ -a $logfile ]; then
        error "$me has already been ran on $(uname -n)... Exiting"
fi

# Check to see if domainname has been set
domainname=`/bin/domainname`
if [ "_$domainname" != "_" ]; then
        error "NIS Domain name is already set to -> $domainname... Exiting."
fi

# Are we already running NIS?
/usr/bin/ypwhich >> $logfile 2>&1
if [ $? -eq 0 ]; then
        error "This system is already running NIS... Exiting."
fi

# Check to see if there is a name service switch config file
if [ -a $nsswitch ]; then
        error "This system has a name service switch config file...
Exiting."
fi

# Check to see if /etc/yp exists
if [ ! -a $ypdir ]; then
        error "Directory /etc/yp does not exist... Exiting"
fi

##
########## System checks out. Set up the files and start NIS.
##

# Set the NIS domain name - This is probably not needed
/bin/domainname $nisdomain >> $logfile 2>&1
if [ $? -ne 0 ]; then
        error "Could not set NIS domain name... Exiting."
fi

# Setup the /etc/netnfsrc file
mv $netnfsrc $netnfsrc.preNIS
cp $netnfsrc.preNIS $netnfsrc
sed -e "s/^NIS_CLIENT=0/NIS_CLIENT=1/"  \
    -e "s/^NISDOMAIN=/NISDOMAIN=cll/" \
    < $netnfsrc > $netnfsrc-tmp
mv $netnfsrc-tmp $netnfsrc
chmod 544 $netnfsrc
chown bin:bin $netnfsrc

# Email us if there are local passwd entries other than root
if [ $( /bin/wc -l $lclpwfile | /usr/bin/cut -d " " -f 1) != "1"  ]; then
        /usr/bin/mailx -s "$(uname -n): passwd.loc has more than 1 line"
$admin < $lclpwfile
fi

# Create NIS passwd file
if [ -a $lclpwfile ]; then
        /bin/grep "^root" $lclpwfile > $nispwfile
else
        /bin/grep "^root" $pwfile > $nispwfile
fi

/bin/cat >> $nispwfile <<:END
adm:*:4:4:,_MoA_:/usr/adm:/bin/sh
anon:*:21:5:placeholder for future,_MoA_:/:/bin/sync
bin:*:2:2:,_MoA_:/bin:/bin/sh
daemon:*:1:5:,_MoA_:/:/bin/sh
ftp:*:24:5:Anonymous &,,,_LcL_:/home/ftp:/bin/sync
ftp:*:500:10:anonymous ftp,_MoA_:/home/ftp:/bin/false
lp:*:9:7:[Line Printer],,,,_MoA_:/usr/spool/lp:/bin/sh
nuucp:*:6:1:0000-uucp(0000),_MoA_:/usr/spool/uucppublic:/usr/lib/uucp/uucico
sync:*:20:1:,_MoA_:/:/bin/sync
tftp:*:510:1:Trivial FTP user,_MoA_:/usr/tftpdir:/bin/false
uucp:*:5:3:,_MoA_:/usr/spool/uucppublic:/usr/lib/uucp/uucico
who:*:90:1:,_MoA_:/:/bin/who
:END

/bin/grep -v "^root" $lclpwfile >> $nispwfile

/bin/cat >> $nispwfile <<:END2
-@dangerous-users
+@sysadmin
+@site-ux
+:
:END2

mv $pwfile $pwfile.preNIS
mv $nispwfile $pwfile
chmod 444 $pwfile
chown root:other $pwfile

# Remove MoA from the root crontab
sed -e "/MoA/d" -e "/mkpass/d" < $crontab > $newcrontab
mv $crontab $crontab-preNIS
/usr/bin/crontab $newcrontab
chmod 444 $crontab
chown root:other $crontab

# Start the NIS Client daemons
/etc/ypbind -ypset >> $logfile 2>&1
sleep 10
/usr/bin/ypwhich >> $logfile 2>&1
if [ $? -ne 0 ]; then
        error "Problem starting the NIS client daemons... Exiting."
fi

# Create /net symlink if automounter is NOT running
/bin/ps -ef | /bin/grep automount | /bin/grep -v grep >> $logfile 2>&1
if [ $? -ne 0 ]; then
        /bin/ln -s /nfs /net >> $logfile 2>&1
fi

# Create symlinks to shells so new passwd file doesn't blow up
/bin/ln -s /bin/sh /usr/bin/sh
/bin/ln -s /bin/csh /usr/bin/csh
/bin/ln -s /bin/ksh /usr/bin/ksh

# Create symlinks to ypdir, not required, just friendlier
/bin/ln -s /usr/etc/yp /var/yp

# Email us that a machine was updated
/usr/bin/mailx -s "$(uname -n): NIS setup complete" $admin < $null
