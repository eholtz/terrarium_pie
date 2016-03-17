#!/bin/bash

# gpio -g write 15 1 => regen ausschalten

if [ $nebel_an ] ; then
	gpio -g write 16 0
else
	gpio -g write 16 1
fi

