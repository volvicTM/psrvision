#!/bin/bash

# Update Ubuntu
echo "Updating Ubuntu..."
apt-get update
apt-get -y upgrade
apt -y dist-upgrade
apt -y autoremove
apt clean
apt purge -y $(dpkg -l | awk '/^rc/ { print $2 }') > /dev/null

# Adduser
echo -n "Please Enter a Username: "
read uname
randompw=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
useradd -d /home/"$uname" -m -g sudo -s /bin/bash "$uname"
echo $uname:$randompw | chpasswd

# Enter SSH Key
mkdir /home/$uname/.ssh
echo "Please Generate a SSH Key with puttygen"
echo -n "Paste the PUBLIC SSH key here: "
read pubkey
echo $pubkey >> /home/$uname/.ssh/authorized_keys
chown $uname:sudo -R /home/$uname/.ssh
chown $uname:sudo -R /home/$uname/.ssh/authorized_keys
chmod 700 /home/$uname/.ssh
chmod 600 /home/$uname/.ssh/authorized_keys

#Secure SSH Login
sed -i 's/Port 22/Port 2245/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin .*/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
systemctl restart sshd
systemctl restart ssh

# adduser to docker group
sudo groupadd docker
sudo usermod -aG docker $uname

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
echo "*** Username: " $uname
echo "*** Password: " $randompw
echo "*** SSH Port: 2245"
echo "****************************"
echo
echo "Reboot the server before continuing." 
echo 
echo
echo
cp /root/psrvision /home/$uname/psrvision
chown -R $uname:sudo /home/$uname/psrvision
chown -R $uname:sudo /home/$uname/psrvision/*
chmod +x /home/$uname/psrvision/appinstall.sh
rm -rf /root/psrvision

exit
