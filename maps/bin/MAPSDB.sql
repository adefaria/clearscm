-------------------------------------------------------------------------------
--
-- File:	$RCSFile$
-- Revision:	$Revision: 1.1 $
-- Description:	This file creates the MAPS database.
-- Author:	Andrew@DeFaria.com
-- Created:	Tue May 13 13:28:18 PDT 2003
-- Modified:	$Date: 2013/06/12 14:05:47 $
-- Language:	SQL
--
-- Copyright (c) 2000-2006, Andrew@DeFaria.com, all rights reserved
--
-------------------------------------------------------------------------------
-- Warning: The following line will delete the old database!
drop database if exists MAPS;

-- Create a new database
create database MAPS;

-- Now let's focus on this new database
use MAPS;

-- user: Valid users and their passwords are contained here
create table user (
  userid			varchar (128)	not null,
  name				tinytext	not null,
  email				varchar (128)	not null,
  password			tinytext	not null,
  primary key (userid)
); -- user

-- useropts: User's options are stored here
create table useropts (
  userid			varchar (128)	not null,
  name				tinytext,
  value				varchar (128),
  key user_index (userid),
  foreign key (userid) references user (userid) on delete cascade
); -- useropts

-- email: Table that holds the email
create table email (
  userid			varchar (128)	not null,
  sender			varchar (128)	not null,
  subject			varchar (255),
  timestamp			datetime,
  data				longblob,
  key user_index (userid),
  foreign key (userid) references user (userid) on delete cascade,
  key sender_index (sender)
); -- email

-- whitelist: Table holds the users' whitelists
create table list (
  userid			varchar (128)	not null,
  type				enum ("white", "black", "null") not null,
  pattern			varchar (128),
  domain			varchar (128),
  comment			varchar (128),
  sequence			smallint,
  hit_count			integer,
  last_hit			datetime,
  key user_index (userid),
  key user_listtype (userid, type),
  unique (userid, type, sequence),
  foreign key (userid) references user (userid) on delete cascade
); -- list

-- log: Table to hold log information
create table log (
  userid			varchar (128)	not null,
  timestamp			datetime,
  sender			varchar (128),
  type				enum (
    "blacklist",
    "debug",
    "error",
    "info",
    "mailloop",
    "nulllist",
    "registered",
    "returned",
    "whitelist"
  ) not null,
  message			varchar (255)	not null,
  key user_index (userid),
  foreign key (userid) references user (userid) on delete cascade
); -- log

-- Create users
--grant all privileges 
--  on MAPS.* to mapsadmin@"%"  identified by "mapsadmin";
--grant select
--  on MAPS.* to mapsreader@"%" identified by "reader";
--grant insert, select, update, delete
--  on MAPS.* to mapswriter@"%" identified by "writer";
