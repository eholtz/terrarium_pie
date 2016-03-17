#!/bin/bash

# gpio -g write 15 1 => regen ausschalten

if [ $regen_an ] ; then
	gpio -g write 15 0
else
	gpio -g write 15 1
fi

