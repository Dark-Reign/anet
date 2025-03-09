#!/bin/bash -e

export EXTERNAL_IP_EXEC_SET="curl -s checkip.amazonaws.com"

echo $EXTERNAL_IP_EXEC_SET

cd /home/alink/etc 
./servfil

echo executing: "$@"
exec "$@"