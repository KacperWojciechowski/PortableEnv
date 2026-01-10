#! /usr/bin/env bash
set -e

IMAGE_NAME="dev-arch"
VOLUME_NAME="dev-workspace"
CONTAINER_WORKDIR="/workspace"

export MSYS_NO_PATHCONV=1

docker run --rm -it \
	-v "$VOLUME_NAME":"$CONTAINER_WORKDIR" \
	-w "$CONTAINER_WORKDIR" \
	-v ~/.ssh/id_ed25519:/home/Dev/.ssh/id_ed25519:ro \
	-v ~/.ssh/id_ed25519.pub:/home/Dev/.ssh/id_ed25519.pub:ro \
	"$IMAGE_NAME"
