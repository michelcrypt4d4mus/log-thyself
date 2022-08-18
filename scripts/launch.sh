#!/bin/bash
# Launches all 3 forward looking streams

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )/

pushd $PARENT_PATH/..
cmd="RAILS_ENV=production thor callthecollecthor:daemon $@"
echo "Executing: $cmd"
eval "$cmd"
