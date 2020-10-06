#!/bin/bash

# Create image and copy to frontend machine
echo "Creating image..."
rm -rf /tmp/image.tgz
tgz-g5k -f /tmp/image.tgz

# default endlocation
endlocation=frontend

# Check for connectivity, atm we cannot connect directly to one machine in lille
if ! ping -c 1 frontend >/dev/null 2>&1
then
    args="-o ProxyJump=root@10.1.8.9,jwuensche@frontend"
    endlocation=lille
fi

echo "Copying image to frontend..."
# Make ssh options available, for e.g. identity file
scp "${@}" "${args}" /tmp/image.tgz "jwuensche@${endlocation}:scionlab.tgz" > /dev/null 2>&1 || exit 1
# Replace old image with new one
# We'll need a key for that, gonna use my account for the time being
echo "Refreshing kaenv3 entry..."
ssh "${@}" "${args}" "jwuensche@${endlocation}" "kaenv3 -d scionlab > /dev/null 2>&1 || kaenv3 -a scionlab.env" > /dev/null 2>&1 || exit 1
echo "Done."

