#!/usr/bin/env bash
set -e

arch="$(dpkg --print-architecture)"

echo "Starting rbfeeder..."

if [ -n "$AIRNAV_RADAR_KEY" ]; then
    echo "#$AIRNAV_RADAR_KEY is already set. Exiting."
    exit
fi

# Purge old log file if it exists.
rm -f /tmp/rbfeeder.log

if [ "$arch" = "i386" ] || [ "$arch" = "amd64" ]; then
    /usr/bin/qemu-arm-static /usr/bin/rbfeeder > /tmp/rbfeeder.log 2>&1 &
    servicePID=$!
else
    /usr/bin/rbfeeder > /tmp/rbfeeder.log 2>&1 &
    servicePID=$!
fi


while true; do
    # Wait for "Please save this key for future use." to appear in the log file
    if grep -q "Please save this key for future use." /tmp/rbfeeder.log; then
        echo "Key detected, stopping rbfeeder..."
        kill $servicePID
        # Show key and exit
        if [ "$arch" = "i386" ] || [ "$arch" = "amd64" ]; then
            /usr/bin/qemu-arm-static /usr/bin/rbfeeder --showkey --no-start
        else
            /usr/bin/rbfeeder --showkey --no-start
        fi
        break
    # If rbfeeder is running, quit.
    elif grep -q "Address already in use" /tmp/rbfeeder.log; then
        echo "Feeder already running, quitting."
        break
    # If timeout during key retrieval, quit.
    elif grep -q "Timeout waiting for new key" /tmp/rbfeeder.log; then
	echo "Timeout waiting for new key. Please try again later."
        break
    fi
    sleep 1
done

# Cleanup.
rm /tmp/rbfeeder.log
