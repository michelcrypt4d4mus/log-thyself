#!/bin/bash
# Launches all 3 forward looking streams

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )/

pushd $PARENT_PATH/..
cmd="RAILS_ENV=production thor collect:syslog:stream $@"
echo "Executing: $cmd"
eval "$cmd"
