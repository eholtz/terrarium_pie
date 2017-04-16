#!/bin/bash

# entry point for the complete terrarium control procedures

source "$(readlink -f $(dirname $0)/../config/files.sh)"

[ $init -eq 1 ] && $dir_script/init.sh

