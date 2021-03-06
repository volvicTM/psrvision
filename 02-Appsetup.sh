#!/bin/bash

# Make required directories
echo "Creating Directories"
mkdir /home/USERNAME/Mount
mkdir /home/USERNAME/Mount/Radarr
mkdir /home/USERNAME/Mount/Radarr/local
mkdir /home/USERNAME/Mount/Radarr/gdrive
mkdir /home/USERNAME/Mount/Radarr/Media
mkdir /home/USERNAME/Mount/4kRadarr
mkdir /home/USERNAME/Mount/4kRadarr/local
mkdir /home/USERNAME/Mount/4kRadarr/gdrive
mkdir /home/USERNAME/Mount/4kRadarr/Media
mkdir /home/USERNAME/Mount/Sonarr
mkdir /home/USERNAME/Mount/Sonarr/local
mkdir /home/USERNAME/Mount/Sonarr/gdrive
mkdir /home/USERNAME/Mount/Sonarr/Media
mkdir /home/USERNAME/Mount/4kSonarr
mkdir /home/USERNAME/Mount/4kSonarr/local
mkdir /home/USERNAME/Mount/4kSonarr/gdrive
mkdir /home/USERNAME/Mount/4kSonarr/Media
mkdir /home/USERNAME/Mount/Plex
mkdir /home/USERNAME/Mount/Plex/Media
mkdir /home/USERNAME/Mount/Plex/Media/4k
mkdir /home/USERNAME/Mount/Plex/Media/Movies
mkdir /home/USERNAME/Mount/Plex/Media/"TV Shows"
mkdir /home/USERNAME/Downloads
mkdir /home/USERNAME/Apps/Plex
mkdir /home/USERNAME/Apps/Sonarr
mkdir /home/USERNAME/Apps/4kSonarr
mkdir /home/USERNAME/Apps/Radarr
mkdir /home/USERNAME/Apps/4kRadarr
mkdir /home/USERNAME/Apps/Nzbget
mkdir /home/USERNAME/Apps/Nzbget/completed
mkdir /home/USERNAME/Apps/NzbHydra
mkdir /home/USERNAME/Apps/Proxy
mkdir /home/USERNAME/.config
mkdir /home/USERNAME/.config/rclone
echo "- Complete"

echo "Creating Scripts"
cp -r /home/USERNAME/psrvision/Scripts /home/USERNAME/Scripts
mkdir /home/USERNAME/Scripts/logs
mkdir /home/USERNAME/Scripts/logs/rclone
mkdir /home/USERNAME/Scripts/logs/plexdrive

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

# Plexdrive
wget https://github.com/dweidenfeld/plexdrive/releases/download/5.0.0/plexdrive-linux-amd64 -P /home/USERNAME/Downloads
sudo chown -R USERNAME:USERNAME /home/USERNAME/Downloads/plexdrive-linux-amd64
chmod +x /home/USERNAME/Downloads/plexdrive-linux-amd64
sudo mv /home/USERNAME/Downloads/plexdrive-linux-amd64 /usr/local/sbin/plexdrive

# Get Plex Claim Code
read -p "Please go to plex.tv/claim and copy and paste the code below: " upclaim
sed -i~ -e "s/USERPCLAIM/${upclaim}/g" 03-DockerSetup.sh


echo "Please Enter your user password to relogin, to enable docker group, then run 03-DockerSetup.sh"
su - $USER

exit
