#!/bin/bash -e

# Create local-servers.txt and populate it with an IP and hostname
echo "- Create local-servers.txt..."
HOSTNAME="${HOSTNAME:=localhost}"
export EXTERNAL_IP_EXEC_SET=`wget -qO- https://checkip.amazonaws.com`
echo "${EXTERNAL_IP_EXEC_SET} $HOSTNAME" > /home/alink/etc/local-servers.txt
cat /home/alink/etc/local-servers.txt

touch /tmp/anet3srv.log
touch /tmp/anet2cron.log

echo "- Execute servfil..."
cd ~/etc 
./servfil

# Deploy public_html/etc
echo "- Deploy public_html/etc"
cd ~/public_html
mkdir -p etc
cd etc
ln -s ~alink/etc/apps.txt apps.txt
ln -s ~alink/etc/names.txt names.txt
ln -s ~alink/etc/servers.txt servers.txt
ln -s ~alink/etc/types.txt types.txt

# Deploy runsrvfil.cgi
echo "- Deploy runsrvfil.cgi..."
cd ~/public_html/etc
cp ../../etc/runsrvfil.cgi .
chmod ug+sx runsrvfil.cgi

echo "- Start game server daemon..."
~alink/etc/start2

echo executing: "$@"
exec "$@"