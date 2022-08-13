#!/bin/bash

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )/

pushd $PARENT_PATH/..
cmd="thor collect:syslog:stream $@"
echo "Executing: $cmd"
eval "$cmd"
popd
