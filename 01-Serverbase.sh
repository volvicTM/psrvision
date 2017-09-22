#!/bin/bash

# Update Ubuntu
echo "Updating Ubuntu..."
apt-get update > /dev/null 2>&1
apt-get -y upgrade > /dev/null 2>&1
apt-get -y dist-upgrade > /dev/null 2>&1
echo "- Complete"
echo "Cleaning Ubuntu..."
apt-get -y autoremove > /dev/null 2>&1
apt-get clean > /dev/null 2>&1
apt-get purge -y $(dpkg -l | awk '/^rc/ { print $2 }') > /dev/null 2>&1
echo "- Complete"

# Adduser
echo "Adding user and SSH Key"
adduser USERNAME
usermod -aG sudo USERNAME

# Enter SSH Key
mkdir /home/USERNAME/.ssh
echo "Please Generate a SSH Key with puttygen"
echo -n "Paste the PUBLIC SSH key here: "
read pubkey
echo $pubkey >> /home/USERNAME/.ssh/authorized_keys
chown USERNAME:USERNAME -R /home/USERNAME/.ssh
chown USERNAME:USERNAME -R /home/USERNAME/.ssh/authorized_keys
chmod 700 /home/USERNAME/.ssh
chmod 600 /home/USERNAME/.ssh/authorized_keys
echo "- Complete"

# Secure SSH Login
echo "Securing Ubuntu"
sed -i 's/Port 22/Port 2245/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin .*/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

# Get UID and GID
id -u USERNAME
read -p "Please enter the above number (UID), exactly as you see it: " uuid
id -g USERNAME
read -p "Please enter the above number (GID), exactly as you see it: " ugid
sed -i~ -e "s/USERUID/${uuid}/g" 03-DockerSetup.sh
sed -i~ -e "s/USERGID/${ugid}/g" 03-DockerSetup.sh

# Secure fstab
echo 'tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0' >> /etc/fstab

# Network Attacks Hardening
cat >/etc/sysctl.conf <<'EOT'
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0 
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0 
net.ipv6.conf.default.accept_redirects = 0

# Ignore Directed pings
net.ipv4.icmp_echo_ignore_all = 1
EOT

# Prevent IP Spoofing
sed -i 's/order hosts,bind/order bind,hosts/' /etc/host.conf
sed -i 's/multi on/nospoof on/' /etc/host.conf
echo "- Complete"

# Disable UFW
ufw disable > /dev/null  2>&1

# Get Plex Claim Code
read -p "Please go to plex.tv/claim and copy and paste the code below: " upclaim
sed -i~ -e "s/USERPCLAIM/${upclaim}/g" 02-Appsetup.sh

echo
echo "Please record your username and password. (You may change the password at any time!)"
echo
echo "****************************"
echo "*** Username: " USERNAME
echo "*** Password: " $randompw
echo "*** SSH Port: 2245"
echo "****************************"
echo
echo "Reboot the server and login with the USERNAME account before continuing." 
echo "Root account has been disabled"

# Move psrvision files to new user account
cp -r /root/psrvision /home/USERNAME/psrvision
chown -R USERNAME:USERNAME /home/USERNAME/psrvision
chown -R USERNAME:USERNAME /home/USERNAME/psrvision/*
rm -rf /root/psrvision

exit
