#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: LDAP.pm,v $
# Revision:     $Revision: 1.3 $
# Description:  The Clearquest LDAP Perl Module.
# Author:       Andrew@ClearSCM.com
# Created:      Fri Sep 22 09:21:18 CDT 2006
# Modified:     $Date: 2011/01/09 01:04:33 $
# Language:     perl
#
# (c) Copyright 2006, ClearSCM, Inc. all rights reserved
#
################################################################################
use strict;
use warnings;

package LDAP;
  use base "Exporter";

  use Carp;
  use OSDep;

  my @MapFields = (
    "CQ_EMAIL",
    "CQ_FULLNAME",
    "CQ_LOGIN_NAME",
    "CQ_MISC_INFO",
    "CQ_PHONE",
  );

  my @ScopeFields = (
    "sub",
    "one",
    "base",
  );

  my @EXPORT = qw (
    MapFields
    ScopeFields
    Validate
    GetSettings
  );

  sub MapFields {
    return @MapFields;
  } # MAPFields

  sub ScopeFields {
    return @ScopeFields;
  } # ScopeFields

  sub Validate {
    my (
      $server,
      $port,
      $base,
      $search_filter,
      $account_attribute,
      $search_for,
    ) = @_;

    eval { require Net::LDAP };

    if ($@) {
      return $FALSE, "Unable to load Net::LDAP. LDAP validation not possible.";
    } # if

    my $ldap = Net::LDAP->new ($server,
      timeout   => 2,
      port      => $port
    );

    return $FALSE, "Unable to connect to $server:$port" if !$ldap;

    if (!$ldap->bind (version => 3)) {
      return $FALSE, "Unable to bind to $server:$port";
    } # if

    my @attribute       = ($account_attribute);
    my $key             = $search_filter;
    $key =~ s/\%login\%/$search_for/;

    my $result = $ldap->search (base    => $base,
                                scope   => "sub",
                                filter  => $key,
                                attrs   => @attribute,
                               );

    $ldap->unbind;

    my $entry = $result->entry;

    if ($entry) {
      my $value =  $entry->get_value ($account_attribute);
      return $TRUE, "Matched $key to LDAP";
    } else {
      return $FALSE, "Unable to find entry ($key)";
    } # if
  } # Validate

  sub GetSettings {
    my $dbset           = shift;
    my $admin_username  = shift;
    my $admin_passwords = shift;

    my %LDAPSettings;

    my $cmd = "installutil getldapinit $dbset $admin_username $admin_passwords";

    my @output = `$cmd`;

    carp "Unable to execute $cmd" if $?;

    foreach (@output) {
      chomp; chop if /\r/;

      next if /^\*|^$/;

      if (/Exit code (\d*)/) {
        $? = $1;
        next;
      } # if

      $LDAPSettings {ldapinit} .= "$_\n";
    } # foreach

    $cmd = "installutil getldapsearch $dbset $admin_username $admin_passwords";

    @output = `$cmd`;

    croak "Unable to execute $cmd" if $?;

    foreach (@output) {
      chomp; chop if /\r/;

      next if /^\*|^$/;

      if (/Exit code (\d*)/) {
        $? = $1;
        next;
      } # if

      $LDAPSettings {ldapsearch} .= "$_\n";
    } # foreach

    $cmd = "installutil getcqldapmap $dbset $admin_username $admin_passwords";

    @output = `$cmd`;

    croak "Unable to execute $cmd" if $?;

    foreach (@output) {
      chomp; chop if /\r/;

      next if /^\*|^$/;

      if (/Exit code (\d*)/) {
        $? = $1;
        next;
      } # if

      $LDAPSettings {cqldapmap} .= "$_\n";
    } # foreach

    return %LDAPSettings;
  } # GetSettings
1;
