#!/bin/bash

# Usage: ./cleanup.sh [container_id]

CONTAINER_ID=$1

docker stop $CONTAINER_ID

docker rm $CONTAINER_ID

VOLUMES=$(docker inspect $CONTAINER_ID --format '{{ range .Mounts }}{{ if eq .Type "volume" }}{{ .Name }} {{ end }}{{ end }}')

if [ ! -z "$VOLUMES" ]; then
    docker volume rm $VOLUMES
fi

IMAGE=$(docker inspect $CONTAINER_ID --format '{{ .Image }}')

if [ ! -z "$IMAGE" ] && [ -z "$(docker ps -a --filter ancestor=$IMAGE --format '{{.ID}}')" ]; then
    docker rmi $IMAGE
fi

docker system prune -f
