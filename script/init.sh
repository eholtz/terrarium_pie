#!/bin/bash

rsync -a "$dir_backup/" "$dir_tmp/"
rm -f $dir_volatile/*

