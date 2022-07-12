--------------------------------------------------------------------------------
--
-- File:        FsmonDB.sql
-- Revision:    0.1
-- Description: Database definition for fsmon
-- Author:	Andrew@ClearSCM.com
-- Created:	Thu Dec 11 13:43:06 MST 2008
-- Modified:	
-- Language:    SQL
--
-- Copyright (c) 2008, General Dynamics, all rights reserved
--
--------------------------------------------------------------------------------
-- Warning: The following line will delete the old database!
drop database if exists fsmon;

-- Create a new database
create database fsmon;

-- Now let's focus on this new database
use fsmon;

-- system: Contains information about the various machines that we are
-- monitoring file systems on

create table system (
  name		varchar(255)	not null,
  owner		tinytext,
  description	text,
  ostype	enum (
		  "Linux",
		  "Unix",
		  "Windows"
		)		not null,
  osversion	tinytext,
  username	tinytext,
  password	tinytext,
  prompt	tinytext,
  shellstyle	enum (
		  "sh",
		  "csh"
		)		not null,

  primary key (name)
) engine = InnoDB;
  
-- filesystems: Describes the filesystems for a system
create table filesystems (
  sysname	varchar(255) 	not null,
  mount		varchar(255)	not null,
  fs		tinytext	not null,

  primary key	(sysname, mount)
) engine = InnoDB;

-- fs: Contains a snapshot reading of a filesystem at a given date and time
create table fs (
  sysname	varchar(255)	not null,
  mount		varchar(255)	not null,
  timestamp	datetime	not null,
  size		bigint,
  used		bigint,  
  free		bigint,
  reserve	bigint,

  primary key	(sysname, mount, timestamp),
  foreign key   (sysname, mount)
    references filesystems (sysname, mount)
      on delete cascade
      on update cascade
) engine = InnoDB;

grant all privileges
  on fsmon.*
  to fsmonadm@"%"
  identified by "fsmonadm" with grant option;

grant select
  on fsmon.*
  to fsmon@"%"
  identified by "fsmon";
