#!/bin/bash

source "$(readlink -f $(dirname $0)/../config/files.sh)"

find $dir_log -mtime +7 -delete {} \;
