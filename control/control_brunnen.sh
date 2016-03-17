#!/bin/bash

# gpio -g write 5 1 => brunnen ausschalten

if [ $brunnen_an ] ; then
	gpio -g write 5 0
else
	gpio -g write 5 1
fi

