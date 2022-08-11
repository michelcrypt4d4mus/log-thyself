#!/bin/bash -e

# Check we're running the script with sudo
if [ $EUID -ne 0 ]; then
    echo You need to run this script with sudo to install a launch daemon.
    echo "  Try re-running with \"sudo \" in front of what you just ran."
    exit
fi


PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
LAUNCHER_PATH=$PWD/scripts/start_log_stream_loader.sh

PLIST_BASENAME=cryptadamus.logloader.plist
PLIST_EXAMPLE=$PARENT_PATH/$PLIST_BASENAME.example
PLIST_LAUNCH_DAEMON_PATH=/Library/LaunchDaemons/$PLIST_BASENAME

# Copy .plist to location
cat $PLIST_EXAMPLE | sed "s+REPLACE_THIS_WITH_PATH_TO_LAUNCH_SCRIPT+${LAUNCHER_PATH}+" | \
    sed "s+REPLACE_WITH_USERNAME+${SUDO_USER}+" > $PLIST_LAUNCH_DAEMON_PATH

echo Wrote plist info to \"$PLIST_LAUNCH_DAEMON_PATH\". Launching...

# Bootstrap service
launchctl bootstrap system "$PLIST_LAUNCH_DAEMON_PATH"
echo launchctl successfully mooned.
