-- -----------------------------------------------------------------------------
--
-- File:        $RCSfile: Machines.sql,v $
-- Revision:    $Revision: 1.$
-- Description: Create the Machines database
-- Author:      Andrew@DeFaria.com
-- Created:     Fri, Jul 13, 2018 10:51:18 AM
-- Modified:    $Date: $
-- Language:    SQL
--
-- Copyright (c) 2010, ClearSCM, Inc., all rights reserved
--
-- -----------------------------------------------------------------------------
-- Warning: The following line will delete the old database!
-- drop database if exists machines;

-- Create a new database
create database machines;

-- Now let's focus on this new database
use machines;

-- system: Define what makes up a system or machine
create table system (
  name             varchar (255) not null,
  model            tinytext,
  alias            varchar (255),
  active           enum (
                     'true',
                     'false'
                   ) not null default 'true',
  admin            tinytext,
  email            tinytext,
  os               tinytext,
  ccver            tinytext,
  type             enum (
                     'Linux',
                     'Unix',
                     'Windows',
                     'Mac'
                   ) not null,
  lastheardfrom    datetime,
  description      text,

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
