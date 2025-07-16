#!/bin/bash
ssh home "cd /opt/songbook && git pull"
rsync -avzu /opt/songbook.master/Music/* home:/opt/songbook/Music
