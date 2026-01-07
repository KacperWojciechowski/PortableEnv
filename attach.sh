#!/usr/bin/env bash
set -e

IMAGE_NAME="dev-arch"
CONTAINER_WORKDIR="/workspace"

export MSYS_NO_PATHCONV=1

CONTAINER_ID=$(docker ps --filter "ancestor=$IMAGE_NAME" --format "{{.ID}}" | head -n 1)

if [ -z "$CONTAINER_ID" ]; then
	echo "No running container found for image '$IMAGE_NAME';"
	exit 1
fi

echo "Attaching to container $CONTAINER_ID..."

docker exec -it -w "$CONTAINER_WORKDIR" "$CONTAINER_ID" fish
