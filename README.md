# LetsEncryptForR1Soft

Script that automatically setups a Let's Encrypt certificate for R1Soft, and handles renewal.

Here is what the script does :
- Installs git (if not already installed)
- Updates the following packages : nss nss-util nss-sysinit nss-tools wget curl ca-certificates openssl
- Clones Let's Encrypt git repository (if not already cloned)
- Stops iptables
- Launches Let's Encrypt certificate creation/renewal
- Starts iptables
- Exits now if the certificate if not yet due to renewal
- Imports the certificate into R1Soft keystore

Just wget the script, change execution rights and launch it (followed by email address as argument) :  
```bash
wget -N https://raw.githubusercontent.com/MegaS0ra/LetsEncryptForR1Soft/master/SSLR1Soft.sh ; chmod +x SSLR1Soft.sh
```  
```bash
./SSLR1Soft.sh your@e.mail
```

You can add a cron every 10 days to renew your certificates :  
```bash
* * */10 * * /root/SSLR1Soft.sh your@e.mail
```  
(Let's Encrypt will only renew the cert if close to expiry).
