#!/bin/bash

source "$(readlink -f $(dirname $0)/../config/files.sh)"
rsync -rP --filter "- log/" --filter "- volatile/" "$dir_tmp/" "$dir_backup/"

