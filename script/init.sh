#!/bin/bash

rsync -r "$dir_backup/" "$dir_tmp/"
rm -f $dir_volatile/*

for pin in "${relaispins[@]}" ; do
  gpio mode $pin out
  gpio write $pin 0
done

