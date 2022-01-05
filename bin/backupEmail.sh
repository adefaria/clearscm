#!/bin/bash
#
# Simple script to backup email store
backupDir=/System/Backups/Email

exclusions=--exclude=.*

ssh defaria.com tar $exclusions -cjf - mail > $backupDir/mail.tar.bz2.$$

mv $backupDir/mail.tar.bz2.$$ $backupDir/mail.tar.bz2
