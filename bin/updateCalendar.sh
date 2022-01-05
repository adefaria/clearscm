#!/bin/bash

# Odd. Seems the following causes wget to use IPv6 instead of IPv4. Well
# recently we turned off IPv6 because we suspect this causes our WiFi 
# dropout problem. But then this hangs.
#wget -O /tmp/calendar.$$.ics 'https://www.google.com/calendar/ical/adefaria%40gmail.com/public/basic.ics' >> /tmp/updateCalendar.$$.log 2>&1
wget --no-check-certificate -O /tmp/calendar.$$.ics 'https://172.217.11.174/calendar/ical/adefaria%40gmail.com/public/basic.ics' >> /tmp/updateCalendar.$$.log 2>&1
wget -O /tmp/meetups.$$.ics 'http://www.meetup.com/events/ical/10426135/8dfdd0ffaaedecf720c5faf0cf3871b7ee5f5c1e/going' >> /tmp/updateCalendar.$$.log 2>&1

wget -4 -O /tmp/tripit.$$.ics 'http://www.tripit.com/feed/ical/private/06C4F90D-EFEFB9C5FDB17EC5FCB327DE31A54D96/tripit.ics' >> /tmp/updateCalendar.$$.log 2>&1

# Now let's combine the files. First strip off the END:CALENDAR from the main 
# file.
filesize=$(wc -l /tmp/calendar.$$.ics | cut -f1 -d' ')
let lines=filesize-1
head -n $lines /tmp/calendar.$$.ics > /tmp/calendar2.$$.ics
mv /tmp/calendar2.$$.ics /tmp/calendar.$$.ics

# Now extract the middle of the next calendar
# Note, if we have nothing RSVPed here for Meetup then the file should be skipped.
# We will get an .ics file but it'll be short - less than 27 lines
filesize=$(wc -l /tmp/meetups.$$.ics | cut -f1 -d' ')

if [ $filesize -gt 27 ]; then
  let lines=filesize-27

  # Get the top portion...
  tail -n $lines /tmp/meetups.$$.ics > /tmp/meetups2.$$.ics

  # Now strip off END:VCALENDAR
  let lines=filesize-27-1

  head -n $lines /tmp/meetups2.$$.ics >> /tmp/calendar.$$.ics

  # Clean up meetups2
  rm -f /tmp/meetups2.$$.ics
fi

# Now extract the middle of the next calendar
filesize=$(wc -l /tmp/tripit.$$.ics | cut -f1 -d' ')

if [ $filesize -gt 27 ]; then
  let lines=filesize-27

  # Get the top portion...
  tail -n $lines /tmp/tripit.$$.ics > /tmp/tripit2.$$.ics

  # Now strip off END:VCALENDAR
  let lines=filesize-27-1

  head -n $lines /tmp/tripit2.$$.ics >> /tmp/calendar.$$.ics

  # Cleanup tripit2
  rm -f /tmp/tripit2.$$.ics
fi

# Now add END:VCALENDAR to calendar.ics
echo "END:VCALENDAR" >> /tmp/calendar.$$.ics

# Move into place
mv /tmp/calendar.$$.ics ~/Documents/calendar.ics

# Get rid of stupid CRs
dos2unix -q ~/Documents/calendar.ics

# Restart rainlendar2
export DISPLAY=:1
killall rainlendar2
rainlendar2 > /tmp/rainlendar2.log 2>&1 &

# Cleanup
rm -rf			\
  /tmp/meetups.$$.ics	\
  /tmp/tripit.$$.ics	\
  /tmp/updateCalendar.$$.log
