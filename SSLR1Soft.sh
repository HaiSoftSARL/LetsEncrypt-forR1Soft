#!/bin/bash
# Execute this script followed by the email address to which the Let's Encrypt certificate's notifications will be sent

if [ $1 -eq 0 ]; then
        echo "Missing argument."
        echo "Please run command followed by email address for LE notifications."
fi

echo -e "\n### Checking requirements..."
rpm -qa | grep "git-"
if test $? -eq 1; then
        yum -y install git
fi
yum -y update nss nss-util nss-sysinit nss-tools wget curl ca-certificates openssl

echo -e "\n### Installing Let's Encrypt..."
if [ ! -d "/root/letsencrypt/" ]; then
        git clone https://github.com/letsencrypt/letsencrypt
fi

echo -e "\n### Certificate creation..."
service iptables stop
./letsencrypt/letsencrypt-auto certonly --standalone --agree-tos -d $(hostname) --rsa-key-size 4096 --email $1
service iptables start

echo -e "\n### Adding certificate to R1Soft..."
cd /etc/letsencrypt/live/$(hostname)/
openssl pkcs8 -topk8 -nocrypt -in privkey.pem -inform PEM -out privkey.pem.der -outform DER
openssl x509 -in fullchain.pem -inform PEM -out fullchain.pem.der -outform DER

cd /usr/sbin/r1soft/jre/bin
chmod 755 java keytool
wget -N https://github.com/MegaS0ra/LetsEncryptForR1Soft/raw/master/importkey.zip
unzip -o importkey.zip

./java ImportKey /etc/letsencrypt/live/$(hostname)/privkey.pem.der /etc/letsencrypt/live/$(hostname)/fullchain.pem.der

echo -e "importkey\npassword\npassword" | ./keytool -storepasswd -keystore /root/keystore.ImportKey

echo -e "password\nimportkey\npassword\npassword" | ./keytool -keypasswd -alias importkey -keystore /root/keystore.ImportKey

/bin/cp /root/keystore.ImportKey /root/keystore ; rm -f /root/keystore.ImportKey

echo -e "password\noui" | ./keytool -import -alias intermed -file /etc/letsencrypt/live/$(hostname)/chain.pem -keystore /root/keystore -trustcacerts

/bin/cp /usr/sbin/r1soft/conf/keystore /usr/sbin/r1soft/conf/keystore.old
/bin/cp /root/keystore /usr/sbin/r1soft/conf/keystore
service cdp-server restart

cd /usr/sbin/r1soft/conf/
echo -e "password" | keytool -delete -keystore keystore -alias cdp

echo -e "password" | keytool -changealias -keystore keystore -alias importkey -destalias cdp

service cdp-server restart
