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
apt-get purge -y $(dpkg -l | awk '/^rc/ { print $2 }')
echo "- Complete"
echo "Adding user and SSH Key"
# Adduser
randompw=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
useradd -d /home/USERNAME -m -g sudo -s /bin/bash USERNAME
echo USERNAME:$randompw | chpasswd

# Enter SSH Key
mkdir /home/USERNAME/.ssh
echo "Please Generate a SSH Key with puttygen"
echo -n "Paste the PUBLIC SSH key here: "
read pubkey
echo $pubkey >> /home/USERNAME/.ssh/authorized_keys
chown plex:sudo -R /home/USERNAME/.ssh
chown plex:sudo -R /home/USERNAME/.ssh/authorized_keys
chmod 700 /home/USERNAME/.ssh
chmod 600 /home/USERNAME/.ssh/authorized_keys
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
usermod -aG docker USERNAME

# Secure fstab
echo 'tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0' >> /etc/fstab

# Prevent IP Spoofing
sed -i 's/order hosts,bind/order bind,hosts/' /etc/host.conf
sed -i 's/multi on/nospoof on/' /etc/host.conf
echo "- Complete"
# Get Domain and write to install scripts
read -p "Go to plex.tv/claim and copy and paste code here: " uclaim
sed -i~ -e "s/USERCLAIM/${uclaim}/g" appinstall.sh
echo
echo "Please record your username and password. (You may change the password at any time!)"
echo
echo "****************************"
echo "*** Username: " USERNAME
echo "*** Password: " $randompw
echo "*** SSH Port: 2245"
echo "****************************"
echo
echo "Reboot the server before continuing." 
cp -r /root/psrvision /home/USERNAME/psrvision
chown -R USERNAME:sudo /home/USERNAME/psrvision
chown -R USERNAME:sudo /home/USERNAME/psrvision/*
chmod +x /home/USERNAME/psrvision/appinstall.sh
rm -rf /root/psrvision

exit
