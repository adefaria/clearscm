package MockCQPerlExt;

use strict;
use warnings;

# Mock CQPerlExt constants
package CQPerlExt;

our $CQ_COMP_OP_EQ          = 1;
our $CQ_COMP_OP_IS_NULL     = 2;
our $CQ_COMP_OP_NEQ         = 3;
our $CQ_COMP_OP_IS_NOT_NULL = 4;
our $CQ_COMP_OP_LT          = 5;
our $CQ_COMP_OP_GT          = 6;
our $CQ_COMP_OP_LTE         = 7;
our $CQ_COMP_OP_GTE         = 8;
our $CQ_COMP_OP_LIKE        = 9;
our $CQ_COMP_OP_NOT_LIKE    = 10;
our $CQ_COMP_OP_BETWEEN     = 11;
our $CQ_COMP_OP_NOT_BETWEEN = 12;
our $CQ_COMP_OP_IN          = 13;
our $CQ_COMP_OP_NOT_IN      = 14;

our $CQ_BOOL_OP_AND = 15;
our $CQ_BOOL_OP_OR  = 16;

our $CQ_Reference_LIST = 6;    # Typo in my thought trace? Check usage
our $CQ_REFERENCE_LIST = 6;
our $CQ_DATE_TIME      = 4;

# Mock CQSession
package CQSession;

sub Build {
  return bless {}, 'CQSession';
}

sub Unbuild {
  return;
}

sub UserLogon {
  my ($self, $user, $pass, $db, $dbset) = @_;

  # Mock successful logon
  return;
} ## end sub UserLogon

sub GetEntityDef {
  my ($self, $table) = @_;
  return bless {table => $table}, 'CQEntityDef';
}

sub BuildEntity {
  my ($self, $table) = @_;
  return bless {table => $table, fields => {}}, 'CQEntity';
}

sub GetEntity {
  my ($self, $table, $key) = @_;
  return bless {table => $table, key => $key, fields => {dbid => "12345"}},
    'CQEntity';
}

sub GetEntityByDbId {
  my ($self, $table, $dbid) = @_;
  return bless {table => $table, key => $dbid, fields => {dbid => $dbid}},
    'CQEntity';
}

sub EditEntity {
  my ($self, $entity, $action) = @_;
  return;
}

sub DeleteEntity {
  my ($self, $entity, $action) = @_;
  return;
}

sub GetInstalledDbSets {
  return ['2.0.0', 'TestDB'];
}

# Mock CQEntityDef
package CQEntityDef;

sub GetFieldDefNames {
  return ['id', 'headline', 'description', 'state', 'owner'];
}

sub IsSystemOwnedFieldDefName {
  my ($self, $field) = @_;
  return 0;
}

sub GetFieldDefType {
  my ($self, $field) = @_;

  # Return STRING (1) for most things, INT (3) for id
  return 3 if $field eq 'id';
  return 1;
} ## end sub GetFieldDefType

# Mock CQEntity
package CQEntity;

sub Validate {
  return '';    # No error
}

sub Commit {
  my ($self) = @_;

  # Simulate DBID generation
  $self->{fields}->{dbid} = "33554432";
  return '';    # No error
} ## end sub Commit

sub Revert {
  return '';
}

sub SetFieldValue {
  my ($self, $field, $value) = @_;
  $self->{fields}->{$field} = $value;
  return '';
}

sub AddFieldValue {
  my ($self, $field, $value) = @_;
  push @{$self->{fields}->{$field}}, $value;
  return '';
}

sub GetFieldValue {
  my ($self, $field) = @_;
  my $val = $self->{fields}->{$field};
  return bless {value => $val}, 'CQField';
}

# Mock CQField
package CQField;

sub GetValue {
  my ($self) = @_;
  return $self->{value};
}

sub GetType {
  return 1;    # Default to STRING
}

sub GetValueAsList {
  my ($self) = @_;
  return $self->{value} || [];
}

1;
