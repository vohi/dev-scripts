#!/bin/sh

CONTAINERS=$(docker ps -aq)

for container in $CONTAINERS;
do
    docker stop $container
    docker rm $container
done

DEAD_IMAGES=$(docker images -aq -f "dangling=true")

for image in $DEAD_IMAGES;
do
    docker rmi $image
done 
