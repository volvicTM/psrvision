#!/bin/bash

# Update Ubuntu
echo "Updating Ubuntu..."
apt-get update > /dev/null
apt-get -y upgrade > /dev/null
apt-get -y dist-upgrade > /dev/null
echo "- Complete"
echo "Cleaning Ubuntu..."
apt-get -y autoremove > /dev/null
apt-get clean > /dev/null
apt-get purge -y $(dpkg -l | awk '/^rc/ { print $2 }') > dev/null
echo "- Complete"
echo "Adding User and SSH Key"
# Adduser

randompw=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
useradd -d /home/plex -m -g sudo -s /bin/bash plex
echo plex:$randompw | chpasswd

# Enter SSH Key
mkdir /home/plex/.ssh
echo "Please Generate a SSH Key with puttygen"
echo -n "Paste the PUBLIC SSH key here: "
read pubkey
echo $pubkey >> /home/plex/.ssh/authorized_keys
chown $uname:sudo -R /home/plex/.ssh
chown $uname:sudo -R /home/plex/.ssh/authorized_keys
chmod 700 /home/plex/.ssh
chmod 600 /home/plex/.ssh/authorized_keys
echo "- Complete"
echo "Securing Ubuntu"
#Secure SSH Login
sed -i 's/Port 22/Port 2245/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin .*/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
systemctl restart sshd
systemctl restart ssh

# adduser to docker group
groupadd docker
usermod -aG docker plex

# Secure fstab
echo 'tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0' >> /etc/fstab

# Source routing hardening
cat >/etc/sysctl.conf <<'EOT'
# IP Spoofing protection
​net.ipv4.conf.all.rp_filter = 1
​net.ipv4.conf.default.rp_filter = 1
​
​# Ignore ICMP broadcast requests
​net.ipv4.icmp_echo_ignore_broadcasts = 1
​
​# Disable source packet routing
​net.ipv4.conf.all.accept_source_route = 0
​net.ipv6.conf.all.accept_source_route = 0 
​net.ipv4.conf.default.accept_source_route = 0
​net.ipv6.conf.default.accept_source_route = 0
​
​# Ignore send redirects
​net.ipv4.conf.all.send_redirects = 0
​net.ipv4.conf.default.send_redirects = 0
​
​# Block SYN attacks
​net.ipv4.tcp_syncookies = 1
​net.ipv4.tcp_max_syn_backlog = 2048
​net.ipv4.tcp_synack_retries = 2
​net.ipv4.tcp_syn_retries = 5
​
​# Log Martians
​net.ipv4.conf.all.log_martians = 1
​net.ipv4.icmp_ignore_bogus_error_responses = 1
​
​# Ignore ICMP redirects
​net.ipv4.conf.all.accept_redirects = 0
​net.ipv6.conf.all.accept_redirects = 0
​net.ipv4.conf.default.accept_redirects = 0 
​net.ipv6.conf.default.accept_redirects = 0
​
​# Ignore Directed pings
​net.ipv4.icmp_echo_ignore_all = 1
EOT

# Prevent IP Spoofing
sed -i 's/order hosts,bind/order bind,hosts/' /etc/host.conf
sed -i 's/multi on/nospoof on/' /etc/host.conf
echo "- Complete"
echo
echo
echo
echo
echo
echo
echo
echo "*Please record your username and password. (You may change the password at any time!)*"
echo
echo "****************************"
echo "*** Username: " plex
echo "*** Password: " $randompw
echo "*** SSH Port: 2245"
echo "****************************"
echo
echo "Reboot the server before continuing." 
echo 
echo
echo "Moving files to new user"
cp -r /root/psrvision /home/plex/psrvision
chown -R $uname:sudo /home/plex/psrvision
chown -R $uname:sudo /home/plex/psrvision/*
chmod +x /home/plex/psrvision/appinstall.sh
rm -rf /root/psrvision

exit
