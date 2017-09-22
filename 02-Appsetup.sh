#!/bin/bash

# Make required directories
echo "Creating Directories"
mkdir /home/USERNAME/Mount
mkdir /home/USERNAME/Mount/Radarr
mkdir /home/USERNAME/Mount/Radarr/local
mkdir /home/USERNAME/Mount/Radarr/gdrive
mkdir /home/USERNAME/Mount/Radarr/Media
mkdir /home/USERNAME/Mount/Sonarr
mkdir /home/USERNAME/Mount/Sonarr/local
mkdir /home/USERNAME/Mount/Sonarr/gdrive
mkdir /home/USERNAME/Mount/Sonarr/Media
mkdir /home/USERNAME/Mount/Plex
mkdir /home/USERNAME/Mount/Plex/Media
mkdir /home/USERNAME/Downloads
mkdir /home/USERNAME/Plex
mkdir /home/USERNAME/Sonarr
mkdir /home/USERNAME/Radarr
mkdir /home/USERNAME/Nzbget
mkdir /home/USERNAME/Nzbget/completed
mkdir /home/USERNAME/NzbHydra
mkdir /home/USERNAME/Proxy
mkdir /home/USERNAME/.config
mkdir /home/USERNAME/.config/rclone
echo "- Complete"

echo "Creating Scripts"
cp /home/USERNAME/psrvision/Scripts /home/USERNAME/Scripts
mkdir /home/USERNAME/Scripts/logs

# Install necessary Applications
echo "Installing Apps"
sudo apt-get -y install unzip fuse unionfs-fuse
sudo sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf

# Docker
sudo apt-get -y install \
apt-transport-https \
ca-certificates \
curl \
software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"
sudo apt-get -y update
sudo apt-get -y install docker-ce
sudo systemctl enable docker
sudo usermod -aG docker USERNAME

# Rclone
wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -P /home/USERNAME/Downloads
unzip /home/USERNAME/Downloads/rclone*.zip -d /home/USERNAME/Downloads/
sudo cp /home/USERNAME/Downloads/rclone*/rclone /usr/local/sbin/rclone
sudo chown root:root /usr/local/sbin/rclone
sudo chmod 755 /usr/local/sbin/rclone
rm -rf /home/USERNAME/Downloads/rclone*
echo "- Complete"

# Get Plex Claim Code
read -p "Please go to plex.tv/claim and copy and paste the code below: " upclaim
sed -i~ -e "s/USERPCLAIM/${upclaim}/g" 03-DockerSetup.sh


echo "Please Enter your user password to relogin, to enable docker group, then run 03-DockerSetup.sh"
su - $USER

exit
