#!/bin/bash

wget -O /tmp/calendar.ics https://calendar.google.com/calendar/ical/adefaria%40gmail.com/public/basic.ics > /tmp/updateCalendar.log 2>&1
wget -O /tmp/allison.ics 'https://calendar.google.com/calendar/ical/7e7c8906758ed8bffdbd7641f29ea7e21847b0ca49b54b8c32d514f7f3a24d28%40group.calendar.google.com/public/basic.ics' > /tmp/updateCalendar.log 2>&1
wget -O /tmp/meetups.ics 'http://www.meetup.com/events/ical/10426135/8dfdd0ffaaedecf720c5faf0cf3871b7ee5f5c1e/going' >> /tmp/updateCalendar.log 2>&1
wget 'https://www.tripit.com/feed/ical/private/06C4F90D-00539C805E8CF5F1C8BC32BF70CB1843/tripit.ics' >> /tmp/updateCalendar.log 2>&1
wget -O /tmp/bsc.ics 'https://bluesuedecrew.com/?post_type=tribe_events&ical=1&eventDisplay=list' >> /tmp/updateCalendar.log 2>&1

# Now let's combine the files. First strip off the END:CALENDAR from the main 
# file.
filesize=$(wc -l /tmp/calendar.ics | cut -f1 -d' ')
let lines=filesize-1
head -n $lines /tmp/calendar.ics > /tmp/calendar2.ics
mv /tmp/calendar2.ics /tmp/calendar.ics

# Now extract the middle of the next calendar
# Note, if we have nothing RSVPed here for Meetup then the file should be skipped.
# We will get an .ics file but it'll be short - less than 27 lines
filesize=$(wc -l /tmp/meetups.ics | cut -f1 -d' ')

if [ $filesize -gt 27 ]; then
  let lines=filesize-27

  # Get the top portion...
  tail -n $lines /tmp/meetups.ics > /tmp/meetups2.ics

  # Now strip off END:VCALENDAR
  let lines=filesize-27-1

  head -n $lines /tmp/meetups2.ics >> /tmp/calendar.ics

  # Clean up meetups2
  rm -f /tmp/meetups2.ics
fi

# Now extract the middle of the next calendar
filesize=$(wc -l /tmp/allison.ics | cut -f1 -d' ')

if [ $filesize -gt 27 ]; then
  # Note: For a shared calendar the header is only 25 lines
  let lines=filesize-25

  # Get the top portion...
  tail -n $lines /tmp/allison.ics > /tmp/allison2.ics

  # Now strip off END:VCALENDAR
  let lines=filesize-27-1

  head -n $lines /tmp/allison2.ics >> /tmp/calendar.ics

  # Cleanup allison2
  rm -f /tmp/allison2.ics
fi

# Now extract the middle of the next calendar
filesize=$(wc -l /tmp/tripit.ics | cut -f1 -d' ')

if [ $filesize -gt 27 ]; then
  let lines=filesize-27

  # Get the top portion...
  tail -n $lines /tmp/tripit.ics > /tmp/tripit2.ics

  # Now strip off END:VCALENDAR
  let lines=filesize-27-1

  head -n $lines /tmp/tripit2.ics >> /tmp/calendar.ics

  # Cleanup tripit2
  rm -f /tmp/tripit2.ics
fi

# Now extract the middle of the next calendar
filesize=$(wc -l /tmp/bsc.ics | cut -f1 -d' ')

if [ $filesize -gt 27 ]; then
  let lines=filesize-27

  # Get the top portion...
  tail -n $lines /tmp/bsc.ics > /tmp/bsc2.ics

  # Now strip off END:VCALENDAR
  let lines=filesize-27-1

  head -n $lines /tmp/bsc2.ics >> /tmp/calendar.ics

  # Cleanup bsc2
  rm -f /tmp/bsc2.ics
fi

# Now add END:VCALENDAR to calendar.ics
echo "END:VCALENDAR" >> /tmp/calendar.ics

# Move into place
mv /tmp/calendar.ics ~/Documents/calendar.ics

# Get rid of stupid CRs
dos2unix -q ~/Documents/calendar.ics

# Restart rainlendar2
export DISPLAY=:1
killall rainlendar2
rainlendar2 > /tmp/rainlendar2.log 2>&1 &

# Cleanup
rm -rf			\
  /tmp/allison.ics	\
  /tmp/meetups.ics	\
  /tmp/tripit.ics	\
  /tmp/bsc.ics		\
  /tmp/updateCalendar.log
