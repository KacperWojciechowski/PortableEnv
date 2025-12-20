#! /usr/bin/env bash
set -e

IMAGE_NAME="dev-arch"
VOLUME_NAME="dev-workspace"
CONTAINER_WORKDIR="/workspace"
SSH_AUTH_SOCK_HOST=${SSH_AUTH_SOCK:-""}

if ! systemctl is-active --quiet docker; then
	echo "Docker daemon is not running. Attempting to start it..."
	sudo systemctl start docker || {
		echo "Failed to start Docker daemon. Exiting."
		exit 1
	}
        echo "Docker daemon started."
fi

echo "Checking SSH agent"
if [ -z "$SSH_AUTH_SOCK_HOST" ]; then
	echo "SSH_AUTH_SOCK is not set. You need to start ssh-agent and add your keys."
	exit 1
fi

docker run --rm -it \
	-v "$VOLUME_NAME":"$CONTAINER_WORKDIR" \
	-v "$SSH_AUTH_SOCK_HOST":/ssh-agent \
	-e SSH_AUTH_SOCK=/ssh-agent \
	-w "$CONTAINER_WORKDIR" \
	"$IMAGE_NAME" \
	fish
