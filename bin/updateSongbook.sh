#!/bin/bash
ssh cloud "cd /opt/songbook && git pull"
rsync -avzu --progress /System/NextCloud/andrew/files/SongBook/Music/ cloud:/opt/songbook/Music
