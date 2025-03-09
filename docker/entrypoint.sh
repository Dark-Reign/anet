#!/bin/bash -e

# Create local-servers.txt and populate it with an IP and hostname
HOSTNAME="${HOSTNAME:=localhost}"
#export EXTERNAL_IP_EXEC_SET=`wget -qO- https://checkip.amazonaws.com`
#echo "${EXTERNAL_IP_EXEC_SET} $HOSTNAME" > /home/alink/etc/local-servers.txt
#cat /home/alink/etc/local-servers.txt

cd ~/etc 
./servfil

# Deploy public_html/etc
cd ~/public_html
mkdir etc
cd etc
ln -s ~alink/etc/apps.txt apps.txt
ln -s ~alink/etc/names.txt names.txt
ln -s ~alink/etc/servers.txt servers.txt
ln -s ~alink/etc/types.txt types.txt

# Deploy runsrvfil.cgi
cd ~/public_html/etc
cp ../../etc/runsrvfil.cgi .
chmod ug+sx runsrvfil.cgi

echo executing: "$@"
exec "$@"