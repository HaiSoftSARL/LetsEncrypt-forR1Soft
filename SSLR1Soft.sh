#!/bin/bash
rpm -qa | grep "git-"
if test $? -eq 1
then
        yum -y install git
fi

if [ ! -d "/root/letsencrypt/" ]; then
        git clone https://github.com/letsencrypt/letsencrypt
fi

service iptables stop
./letsencrypt/letsencrypt-auto certonly --standalone -d $(hostname) --rsa-key-size 4096
service iptables start

cd /etc/letsencrypt/live/$(hostname)/
openssl pkcs8 -topk8 -nocrypt -in privkey.pem -inform PEM -out privkey.pem.der -outform DER
openssl x509 -in fullchain.pem -inform PEM -out fullchain.pem.der -outform DER

cd /usr/sbin/r1soft/jre/bin
chmod 755 java keytool
#scp importkey.zip root@$(hostname):/usr/sbin/r1soft/jre/bin/
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
