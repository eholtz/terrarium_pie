#!/bin/bash

source ../config/files.sh
rsync -a "$dir_tmp/" "$dir_backup/"

