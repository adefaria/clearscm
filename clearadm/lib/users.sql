-- -----------------------------------------------------------------------------
--
-- File:        $RCSfile: users.sql,v $
-- Revision:    $Revision: 1.1 $
-- Description: Create users for clearscm
-- Author:      Andrew@ClearSCM.com
-- Created:     Tue Nov 30 08:46:42 EST 2010
-- Modified:    $Date: 2010/12/13 17:16:30 $
-- Language:    SQL
--
-- Copyright (c) 2010, ClearSCM, Inc., all rights reserved
--
-- -----------------------------------------------------------------------------
grant all privileges 
  on clearadm.*
  to clearadm@"%"
identified by 'clearscm';

grant select
  on clearadm.*
  to cleareader@"%"
identified by 'cleareader';

grant insert, select, update, delete
  on clearadm.*
  to clearwriter@"%"
identified by 'clearwriter';
