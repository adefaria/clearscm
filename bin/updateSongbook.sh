#!/bin/bash
ssh home "cd /opt/songbook && git pull"
rsync -rauv /opt/songbook.master/Music/* home:/opt/songbook/Music
