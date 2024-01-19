#!/bin/bash
ssh home "cd /opt/songbook && git pull"
rsync -rau /opt/songbook.master/Music/* home:/opt/songbook/Music
