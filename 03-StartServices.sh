#! /bin/bash

# Run Mounts
sh /home/USERNAME/Scripts/sonarrmount.sh
sleep 2
sh /home/USERNAME/Scripts/radarrmount.sh
sleep 2
sh /home/USERNAME/Scripts/plexmount.sh
sleep 2

# Start Dockers in Proxy Order
docker start letsencrypt
sleep 3
docker start nzbget
sleep 3
docker start sonarr
sleep 3
docker start radarr
sleep 3
docker start hydra
sleep 3
docker start plex

exit
