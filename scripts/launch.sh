#!/bin/bash
# Launches all 3 forward looking streams
# Your working/current dir should be project root when you run this.

cmd="RAILS_ENV=production thor callthecollecthor:daemon $@"
echo "Executing: $cmd"
eval "$cmd"
