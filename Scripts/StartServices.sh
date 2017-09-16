#! /bin/bash

# Unmount mounts and Stop Dockers
echo "Stopping Containers and unmounting."
docker stop $(docker ps -a -q) > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Radarr/gdrive > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Radarr/local > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Radarr/Media > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Sonarr/gdrive > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Sonarr/local > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Sonarr/Media > /dev/null 2>&1
/bin/fusermount -uz /home/USERNAME/Plex/Media > /dev/null 2>&1
echo "- Completed"

# Start Containers
echo "Starting Containers"
docker start letsencrypt > /dev/null 2>&1
sleep 3
docker start plex > /dev/null 2>&1
sleep 3
docker start sonarr > /dev/null 2>&1
sleep 3
docker start radarr > /dev/null 2>&1
sleep 3
docker start hydra > /dev/null 2>&1
sleep 3
docker start nzbget > /dev/null 2>&1
sleep 3
echo "- Completed"

# Run Mounts
echo "Mounting Google Drive Mounts"
sh /home/USERNAME/Scripts/sonarrmount.sh > /dev/null 2>&1
sleep 2
sh /home/USERNAME/Scripts/radarrmount.sh > /dev/null 2>&1
sleep 2
sh /home/USERNAME/Scripts/plexmount.sh > /dev/null 2>&1
sleep 2
echo "- Completed"

exit
