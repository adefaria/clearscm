-------------------------------------------------------------------------------
--
-- File:        $RCSFile$
-- Revision:    $Revision: 1.1 $
-- Description: This file creates the MAPS database.
-- Author:      Andrew@DeFaria.com
-- Created:     Tue May 13 13:28:18 PDT 2003
-- Modified:    $Date: 2013/06/12 14:05:47 $
-- Language:    SQL
--
-- Copyright (c) 2000-2006, Andrew@DeFaria.com, all rights reserved
--
-------------------------------------------------------------------------------
-- Warning: The following line will delete the old database!
drop database if exists MAPS;

-- Create a new database
create database MAPS CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Now let's focus on this new database
use MAPS;

-- user: Valid users and their passwords are contained here
create table user (
  userid      varchar (128) not null,
  name        tinytext      not null,
  email       varchar (128) not null,
  password    tinytext      not null,
  primary key (userid)
); -- user

-- useropts: User's options are stored here
create table useropts (
  userid         varchar (128) not null,
  name           tinytext,
  value          varchar (128),
  key user_index (userid),
  foreign key (userid) references user (userid) on delete cascade
); -- useropts

-- email: Table that holds the email
create table email (
  userid           varchar (128) not null,
  sender           varchar (128) not null,
  subject          varchar (255),
  timestamp        datetime,
  data             longblob,
  key user_index   (userid),
  foreign key      (userid) references user (userid) on delete cascade,
  key sender_index (sender)
); -- email

-- list: Table holds the users' various lists
create table list (
  userid            varchar (128)                   not null,
  type              enum ("white", "black", "null") not null,
  pattern           varchar (128),
  domain            varchar (128),
  comment           varchar (128),
  sequence          smallint,
  hit_count         integer,
  last_hit          datetime,

-- Retention: This field indicates how much time must pass before an inactive
--            list entry should be scrubbed. Null indicates retain forever.
--            other values include "x day(s)", "x month(s)", "x year(s)". So,
--            for example, a user on the white list may have its retention set
--            to say 1 year and when mapsscrub runs, if last_hit is older than
--            a year the whitelist entry would be removed. If, however, 
--            retention is null then the record is kept forever. This is useful
--            for the null and black lists where one might want to insure that
--            a particular domain (e.g. @talentburst.com) will never come off
--            of the nulllist.
  retention         varchar (40),
  key user_index    (userid),
  key user_listtype (userid, type),
  unique            (userid, type, sequence),
  foreign key       (userid) references user (userid) on delete cascade
); -- list

-- log: Table to hold log information
create table log (
  userid    varchar (128) not null,
  timestamp datetime,
  sender    varchar (128),
  type      enum (
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
  message        varchar (255) not null,
  key user_index (userid),
  foreign key     (userid) references user (userid) on delete cascade
); -- log

-- Create users
-- New 8.0 syntax...
--create user 'maps'@'localhost' identified by 'spam';
grant all privileges on MAPS.* to 'maps'@'localhost';
