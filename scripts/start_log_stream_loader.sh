#!/bin/bash
# Launcher script. TODO: replace with calls to thor.

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )/
options=$@

if [[ -z $options ]]; then
    options='--stream --log-level info'
fi

cd "$PARENT_PATH"

cmd="bundle exec rails r scripts/collect_logs.rb $options"
echo $cmd
eval $cmd
