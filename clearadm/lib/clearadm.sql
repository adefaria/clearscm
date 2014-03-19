-- -----------------------------------------------------------------------------
--
-- File:        $RCSfile: clearadm.sql,v $
-- Revision:    $Revision: 1.23 $
-- Description: Create the clearadm database
-- Author:      Andrew@DeFaria.com
-- Created:     Tue Nov 30 08:46:42 EST 2010
-- Modified:    $Date: 2011/02/09 13:28:33 $
-- Language:    SQL
--
-- Copyright (c) 2010, ClearSCM, Inc., all rights reserved
--
-- -----------------------------------------------------------------------------
-- Warning: The following line will delete the old database!
-- drop database if exists clearadm;

-- Create a new database
create database clearadm;

-- Now let's focus on this new database
use clearadm;

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
  region	         tinytext,
  port             int default 25327,
  lastheardfrom    datetime,
  notification     varchar (255),
  description	     text,
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

-- clearcase: Information about a Clearcase system
create table clearcase (
  system                    varchar (255) not null,
  ccver                     tinytext,
  hardware                  tinytext,
  licenseHost               tinytext,
  registryHost              tinytext,
  mvfsBlocksPerDirectory    int,
  mvfsCleartextMnodes       int,
  mvfsDirectoryNames        int,
  mvfsFileNames             int,
  mvfsFreeMnodes            int,
  mvfsInitialMnodeTableSize int,
  mvfsMinCleartextMnodes    int,
  mvfsMinFreeMnodes         int,
  mvfsNamesNotFound         int,
  mvfsRPCHandles            int,
  interopRegion             int,
  scalingFactor             int,
  cleartextIdleLifetime     int,
  vobHashTableSize          int,
  cleartextHashTableSize    int,
  dncHashTableSize          int,
  threadHashTableSize       int,
  processHashTableSize      int,

  foreign key systemLink (system) references system (name) 
    on delete cascade
    on update cascade,
  primary key (system)
) engine=innodb; -- clearcase

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

-- vobs: Describe a system's vobs
create table vob (
  system varchar (255) not null,
  tag    varchar (255) not null,
  
  key systemIndex (system),
  foreign key systemLink (system) references system (name)
    on delete cascade
    on update cascade,
  primary key (tag)
) engine=innodb; -- vob 

-- view: Describe views
create table view (
  system    varchar (255) not null,
  region    varchar (255) not null,
  tag       varchar (255) not null,
  owner     tinytext,
  ownerName tinytext,
  email     tinytext,
  type      enum (
              'dynamic',
              'snapshot',
              'web'
            ) not null default 'dynamic',
  gpath     tinytext,
  modified  datetime,
  timestamp datetime,
  age       tinytext,
  ageSuffix tinytext,
  
  key systemIndex (system),
  foreign key systemLink (system) references system (name)
    on delete cascade
    on update cascade,
  key regionIndex (region),
  primary key (region, tag)
) engine=innodb; -- view

create table task (
  name          varchar (255) not null,
  system        varchar (255),
  description   text,
  command       text not null,
  restartable   enum (
                  'true',
                  'false'
                ) not null default 'true',
  
  primary key (name)
--  primary key (name),
--  foreign key systemLink (system) references system (name)
--    on delete cascade
--    on update cascade
) engine=innodb; -- task

create table runlog (
  id            int not null auto_increment,
  task          varchar (255) not null,
  system        varchar (255),
  started       datetime,
  ended         datetime,
  alerted       enum (
                  'true',
                  'false'
                ) not null default 'false',
  status        int,
  message       text,
  
  primary key (id, task, system),
  foreign key taskLink (task) references task (name)
    on delete cascade
    on update cascade,
  foreign key systemLink (system) references system (name)
    on delete cascade
    on update cascade
) engine=innodb; -- runlog
  
create table alert (
  name varchar (255) not null,
  type enum (
         'email',
         'page',
         'im'
       ) not null default 'email',
  who  tinytext,
  
  primary key (name)
) engine=innodb; -- alert

create table notification (
  name         varchar (255) not null,
  alert        varchar (255) not null,
  cond         tinytext not null,
  nomorethan   enum (
                 'Once an hour',
                 'Once a day',
                 'Once a week',
                 'Once a month'
               ) not null default 'Once a day',
  
  primary key (name),
  foreign key alertLink (alert) references alert (name)
    on delete cascade
    on update cascade
 ) engine=innodb; -- notification
 
create table schedule (
  name          varchar (255) not null,
  task          varchar (255) not null,
  notification  varchar (255) not null,
  frequency     tinytext,
  active        enum (
                  'true',
                  'false'
                ) not null default 'true',
  lastrunid     int,
  
  primary key (name),
  foreign key taskLink (task) references task (name)
    on delete cascade
    on update cascade,
  foreign key notificationLink (notification) references notification (name)
    on delete cascade
    on update cascade
) engine=innodb; -- schedule

create table alertlog (
  id           int not null auto_increment,
  alert        varchar (255) not null,
  system       varchar (255) not null,
  notification varchar (255) not null,
  runlog       int not null,
  timestamp    datetime,
  message      text,
  
  primary key (id, alert),
  key         (system),
  foreign key alertLink (alert) references alert (name)
    on delete cascade
    on update cascade,
  foreign key notificationLink (notification) references notification (name)
    on delete cascade
    on update cascade,
  foreign key runlogLink (runlog) references runlog (id)
    on delete cascade
    on update cascade
) engine=innodb; -- alertlog
