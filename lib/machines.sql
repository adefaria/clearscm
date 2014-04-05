system-- -----------------------------------------------------------------------------
--
-- File:        $RCSfile: machines.sql,v $
-- Revision:    $Revision: 1.0 $
-- Description: Create the machines database
-- Author:      Andrew@DeFaria.com
-- Created:     Fri Apr  4 10:31:11 PDT 2014
-- Modified:    $Date: $
-- Language:    SQL
--
-- Copyright (c) 2014, ClearSCM, Inc., all rights reserved
--
-- -----------------------------------------------------------------------------
-- Warning: The following line will delete the old database!
drop database if exists machines;

-- Create a new database
create database machines;

-- Now let's focus on this new database
use machines;

-- system: Define what makes up a system or machine
create table system (
  name             varchar (255) not null,
  alias            varchar (255),
  active           enum (
                     'true',
                     'false'
                   ) not null default 'true',
  admin            tinytext,
  email            tinytext,
  os               tinytext,
  type             enum (
                     'Linux',
                     'Unix',
                     'Windows'
                   ) not null,
  region           tinytext,
  lastheardfrom    datetime,
  description      text,
  loadavgHist      enum (
                     '1 month',
                     '2 months',
                     '3 months',
                     '4 months',
                     '5 months',
                     '6 months',
                     '7 months',
                     '8 months',
                     '9 months',
                     '10 months',
                     '11 months',
                     '1 year'
                   ) not null default '6 months',
  loadavgThreshold float (4,2) default 5.00,

  primary key (name)
) engine=innodb; -- system

-- package: A package is any software package that we wish to keep track of
create table package (
  system      varchar (255) not null,
  name        varchar (255) not null,
  version     tinytext not null,
  vendor      tinytext,
  description text,

  key packageIndex (name),
  key systemIndex (system),
  foreign key systemLink (system) references system (name)
    on delete cascade
    on update cascade,
  primary key (system, name)
) engine=innodb; -- package
  
-- filesystem: A systems file systems that we are monitoring 
create table filesystem (
  system         varchar (255) not null,
  filesystem     varchar (255) not null,
  fstype         tinytext not null,
  mount          tinytext,
  threshold      int default 90,
  notification   varchar (255),
  filesystemHist enum (
                   '1 month',
                   '2 months',
                   '3 months',
                   '4 months',
                   '5 months',
                   '6 months',
                   '7 months',
                   '8 months',
                   '9 months',
                   '10 months',
                   '11 months',
                   '1 year'
                 ) not null default '6 months',
  
  key filesystemIndex (filesystem),
  foreign key systemLink (system) references system (name)
    on delete cascade
    on update cascade,
  primary key (system, filesystem)
) engine=innodb; -- filesystem

-- fs: Contains a snapshot reading of a filesystem at a given date and time
create table fs (
  system         varchar(255) not null,
  filesystem     varchar(255) not null,
  mount          varchar(255) not null,
  timestamp      datetime     not null,
  size           bigint,
  used           bigint,
  free           bigint,
  reserve        bigint,

  key mountIndex (mount), 
  primary key   (system, filesystem, timestamp),
  foreign key   filesystemLink (system, filesystem)
    references filesystem (system, filesystem)
      on delete cascade
      on update cascade
) engine=innodb; -- fs

-- loadavg: Contains a snapshot reading of a system's load average
create table loadavg (
  system        varchar(255)    not null,
  timestamp     datetime        not null,
  uptime        tinytext,
  users         int,
  loadavg       float (4,2),

  primary key   (system, timestamp),
  foreign key systemLink (system) references system (name)
    on delete cascade
    on update cascade
) engine=innodb; -- loadavg