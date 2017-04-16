#!/bin/bash

rsync -r "$dir_backup/" "$dir_tmp/"
rm -f $dir_volatile/*

