#!/bin/bash

# gpio -g write 5 1 => brunnen ausschalten

if [ $brunnen_an ] ; then
	turnon 5 "brunnen.turned.on"
else
	turnoff 5 "brunnen.turend.off"
fi

