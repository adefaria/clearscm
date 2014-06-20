-- -----------------------------------------------------------------------------
--
-- File:        $RCSfile: load.sql,v $
-- Revision:    $Revision: 1.10 $
-- Description: Create predefined data in the Clearadm database
-- Author:      Andrew@ClearSCM.com
-- Created:     Tue Nov 30 08:46:42 EST 2010
-- Modified:    $Date: 2012/07/04 20:51:34 $
-- Language:    SQL
--
-- Copyright (c) 2010, ClearSCM, Inc., all rights reserved
--
-- -----------------------------------------------------------------------------
-- Predefined alerts
insert into alert (
  name,
  type
) values (
  'Email admin',
  'email'
);

-- Predefined notificationsTables
insert into notification (
  name,
  alert,
  cond,
  nomorethan
) values (
  'Filesystem',
  'Email admin',
  'Filesystem over threshold',
  'Once a day'
);

insert into notification (
  name,
  alert,
  cond,
  nomorethan
) values (
  'Heartbeat',
  'Email admin',
  'Heartbeat Failure',
  'Once an hour'
);

insert into notification (
  name,
  alert,
  cond,
  nomorethan
) values (
  'Loadavg',
  'Email admin',
  'Loadavg over threshold',
  'Once an hour'
);

insert into notification (
  name,
  alert,
  cond,
  nomorethan
) values (
  'Scrub',
  'Email admin',
  'Scrub Failure',
  'Once a day'
);

insert into notification (
  name,
  alert,
  cond,
  nomorethan
) values (
  'System checkin',
  'Email admin',
  'Not respoding',
  'Once an hour'
);

insert into notification (
  name,
  alert,
  cond,
  nomorethan
) values (
  'Update systems',
  'Email admin',
  'Non zero return',
  'Once an hour'
);

-- Predefined tasks
insert into task (
  name,
  system,
  description,
  command
) values (
  'Loadavg',
  'Localhost',
  'Obtain a loadavg snapshot on all systems',
  'updatela.pl'
);

insert into task (
  name,
  system,
  description,
  command
) values (
  'Filesystem',
  'Localhost',
  'Obtain a filesystem snapshot on all systems/filesystems',
  'updatefs.pl'
);

insert into task (
  name,
  system,
  description,
  command
) values (
  'Scrub',
  'Localhost',
  'Scrub Clearadm database',
  'clearadmscrub.pl'
);

insert into task (
  name,
  system,
  description,
  command
) values (
  'System checkin',
  'Localhost',
  'Checkin from all systems',
  'default'
);

insert into task (
  name,
  system,
  description,
  command
) values (
  'Update systems',
  'Localhost',
  'Update all systems',
  'updatesystem.pl -host all'
);

-- Predefined schedule
insert into schedule (
  name,
  task,
  notification,
  frequency
) values (
  'Loadavg',
  'Loadavg',
  'LoadAvg',
  '5 Minutes'
);

insert into schedule (
  name,
  task,
  notification,
  frequency
) values (
  'Filesystem',
  'Filesystem',
  'Filesystem',
  '5 Minutes'
);

insert into schedule (
  name,
  task,
  notification,
  frequency
) values (
  'Scrub',
  'Scrub',
  'Scrub',
  '1 day'
);
