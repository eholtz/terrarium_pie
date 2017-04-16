#!/bin/bash

source "$(readlink -f $(dirname $0)/../config/files.sh)"
rsync -a "$dir_tmp/" "$dir_backup/"

