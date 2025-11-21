#!/bin/bash
ssh home "cd /opt/songbook && git pull"
rsync -avzu --progress /System/NextCloud/andrew/files/SongBook/Music/ home:/opt/songbook/Music
