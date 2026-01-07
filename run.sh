#! /usr/bin/env bash
set -e

IMAGE_NAME="dev-arch"
VOLUME_NAME="dev-workspace"
CONTAINER_WORKDIR="/workspace"

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

export MSYS_NO_PATHCONV=1

docker run --rm -it \
	-v "$VOLUME_NAME":"$CONTAINER_WORKDIR" \
	-w "$CONTAINER_WORKDIR" \
	-v "$SSH_AUTH_SOCK:/ssh-agent" \
	-e SSH_AUTH_SOCK=/ssh-agent \
	"$IMAGE_NAME" \
	fish
