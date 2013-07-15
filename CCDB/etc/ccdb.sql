-- -----------------------------------------------------------------------------
--
-- File:        $RCSfile: ccdb.sql,v $
-- Revision:    $Revision: 1.3 $
-- Description: Clearcase DB
-- Author:      Andrew@ClearSCM.com
-- Created:     Wed Mar 14 15:53:12 PDT 2011
-- Modified:    $Date: 2011/04/15 22:19:21 $
-- Language:    SQL
--
-- Copyright (c) 2011, Tellabs, Inc., all rights reserved
--
-- -----------------------------------------------------------------------------
-- Warning: The following line will delete the old database!
drop database if exists ccdb;

-- Create a new database
create database ccdb;

-- Now let's focus on this new database
use ccdb;

-- registry: Defines a registry region
create table registry (
  name	          varchar (767) collate latin1_general_cs not null,

  primary key (name)
) type=innodb; -- registry

-- region: Defines a region within a registry
create table region (
  name             varchar (767) collate latin1_general_cs not null,
  registry         varchar (767) collate latin1_general_cs not null,

  primary key (registry, name),
  key regionIndex (name),
  foreign key registryLink (registry) references registry (name)
    on delete cascade
    on update cascade
) type=innodb; -- region

-- vob: Defines a vob
create table vob (
  oid             char (41),
  name            varchar (767) collate latin1_general_cs not null,
  epoch           bigint default 0,
  type            enum (
                    'base',
                    'ucm'
                  ) not null default 'base',

  primary key (oid),
  key nameIndex (name)
) type=innodb; -- vob

-- folder: Defines a UCM folder
create table folder (
  oid            char (41),
  name           varchar (767) collate latin1_general_cs not null,
  pvob           varchar (767) collate latin1_general_cs not null,

  primary key (oid),
  key nameIndex (name),
  foreign key pvobLink (pvob) references vob (name)
    on delete cascade
    on update cascade
) type=innodb; -- folder

-- subfolder: Defines a UCM subfolder
create table subfolder (
  parent         varchar (767) collate latin1_general_cs not null,
  subfolder      varchar (767) collate latin1_general_cs not null,
  pvob           varchar (767) collate latin1_general_cs not null,

  primary key (parent, subfolder, pvob),
  foreign key parentLink (parent) references folder (name)
    on delete cascade
    on update cascade,
  foreign key subfolderLink (subfolder) references folder (name)
    on delete cascade
    on update cascade,
  foreign key pvobLink (pvob) references vob (name)
    on delete cascade
    on update cascade
) type=innodb; -- subfolder
  
-- project: Defines a UCM project
create table project (
  oid             char (41),
  name            varchar (767) collate latin1_general_cs not null,
  folder          varchar (767) collate latin1_general_cs not null,
  pvob            varchar (767) collate latin1_general_cs not null,

  primary key (oid),
  key projectIndex (name),
  key folderIndex (folder),
  foreign key folderLink (folder) references folder (name)
    on delete cascade
    on update cascade,
  foreign key pvobLink (pvob) references vob (name)
    on delete cascade
    on update cascade
) type=innodb; -- project

-- stream: Defines a UCM stream
create table stream (
  oid             char (41),
  name            varchar (767) collate latin1_general_cs not null,
  pvob            varchar (767) collate latin1_general_cs not null,
  project         varchar (767) collate latin1_general_cs not null,
  type            enum (
                    'integration',
                    'regular'
                  ) not null default 'regular',

  primary key (oid),
  key streamIndex (name),
  foreign key pvobLink (pvob) references vob (name)
    on delete cascade
    on update cascade,
  foreign key projectLink (project) references project (name)
    on delete cascade
    on update cascade
) type=innodb; -- stream

-- activity: Defines an activity
create table activity (
  oid             char (41),
  name            varchar (767) collate latin1_general_cs not null,
  pvob            varchar (767) collate latin1_general_cs not null,
  type            enum (
                    'integration',
                    'regular'
                  ) not null default 'regular',
  submitted       datetime,

  primary key (oid),
  key activityIndex (name),
  foreign key pvobLink (pvob) references vob (name)
    on delete cascade
    on update cascade
) type=innodb; -- activity

-- baseline: Defines a baseline
create table baseline (
  oid             char (41),
  name            varchar (767) collate latin1_general_cs not null,
  pvob            varchar (767) collate latin1_general_cs not null,

  primary key (oid),
  key baselineIndex (name),
  foreign key pvobLink (pvob) references vob (name)
    on delete cascade
    on update cascade
) type=innodb; -- baseline

-- Cross references
create table stream_activity_xref (
  stream          varchar (767) collate latin1_general_cs not null,
  activity        varchar (767) collate latin1_general_cs not null,
  pvob            varchar (767) collate latin1_general_cs not null,

  primary key (stream, activity, pvob),
  key streamIndex (stream),
  key activityIndex (activity),
  key pvobIndex (pvob),
  foreign key streamLink (stream) references stream (name)
    on delete cascade
    on update cascade,
  foreign key activityLink (activity) references activity (name)
    on delete cascade
    on update cascade,
  foreign key pvobLink (pvob) references vob (name)
    on delete cascade
    on update cascade
) type=innodb; -- stream_activity_xref

create table stream_baseline_xref (
  stream          varchar (767) collate latin1_general_cs not null,
  baseline        varchar (767) collate latin1_general_cs not null,
  pvob            varchar (767) collate latin1_general_cs not null,

  primary key (stream, baseline, pvob),
  key streamIndex (stream),
  key baselineIndex (baseline),
  key pvobIndex (pvob),
  foreign key streamLink (stream) references stream (name)
    on delete cascade
    on update cascade,
  foreign key baselineLink (baseline) references baseline (name)
    on delete cascade
    on update cascade,
  foreign key pvobLink (pvob) references vob (name)
    on delete cascade
    on update cascade
) type=innodb; -- stream_baseline_xref


create table changeset (
  activity        varchar (767) collate latin1_general_cs not null,
  element         varchar (767) collate latin1_general_cs not null,
  version         varchar (767) collate latin1_general_cs not null,
  pvob            varchar (767) collate latin1_general_cs not null,
  created         datetime,
  
  primary key (activity, element, version, pvob),
  key activityIndex (activity),
  key elementIndex (element),
  key elementVersionIndex (version),
  foreign key activityLink (activity) references activity (name)
    on delete cascade
    on update cascade,
  foreign key pvobLink (pvob) references vob (name)
    on delete cascade
    on update cascade
) type=innodb; -- changeset

create table baseline_activity_xref (
  baseline        varchar (767) collate latin1_general_cs not null,
  activity        varchar (767) collate latin1_general_cs not null,
  pvob            varchar (767) collate latin1_general_cs not null,
  
  primary key (baseline, activity, pvob),
  key baselineIndex (baseline),
  key activityIndex (activity),
  foreign key baselineLink (baseline) references baseline (name)
    on delete cascade
    on update cascade,
  foreign key activityLink (activity) references activity (name)
    on delete cascade
    on update cascade,
  foreign key pvobLink (pvob) references vob (name)
    on delete cascade
    on update cascade
) type=innodb; -- baseline_activity_xref
