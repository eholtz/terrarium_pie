#!/bin/bash

# gpio -g write 11 1 => licht ausschalten

source lichtdefs.sh

if [ $tag_licht ] && [ ! -f $sem ] ; then
  # sunrise wurde noch nicht gestartet, wenn die semaphore fehlt
  date > $sem
  ./control_sunrise.sh &
elif [ $nacht_licht ] && [ -f $sem ] ; then
  rm $sem
  ./control_sunset.sh &
elif [ $tag_licht ] && [ $(ps -ef | grep control_sun | grep -v grep | wc -l) -eq 0 ]; then
  # es ist tag, der sonnenaufgang ist vorbei
  turnon 11 $onf
fi

