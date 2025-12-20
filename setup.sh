#!/usr/bin/env bash
set -e

if [[ $# -lt 1 || -z "$1" ]]; then
	echo "ERROR: GIT_USER not provided - GitHub user name required, in order to support initial repo cloning"
	echo "Usage: ./setup.sh <github-username>"
	exit 1
fi

GIT_USER="$1"

VOLUME_NAME="dev_workspace"
IMAGE_NAME="dev-arch"
DOCKERFILE_PATH="./Dockerfile"
CONTEXT_DIR="."

echo "Cleaning up dangling Docker volumes..."
docker volume prune -f

echo "Docker cleanup completed"

echo "Checking if Docker volume '$VOLUME_NAME' exists..."
if ! docker volume inspect "$VOLUME_NAME" > /dev/null 2>&1; then
	echo "Volume '$VOLUME_NAME' does not exist. Creating..."
	docker volume create "$VOLUME_NAME"
	echo "Volume '$VOLUME_NAME' created."
else
	echo "Volume '$VOLUME_NAME' found."
fi

echo "Building Docker image '$IMAGE_NAME' from $DOCKERFILE_PATH..."
DOCKER_BUILDKIT=1 docker build \
	--build-arg GIT_USER="$GIT_USER" \
	--ssh default \ # temporarily forwards ssh to allow for cloning during image build
	-t "$IMAGE_NAME" \
	-f "$DOCKERFILE_PATH" \
	"$CONTEXT_DIR"
echo "Docker image '$IMAGE_NAME' built successfully."

echo "Setup complete. Volume: $VOLUME_NAME | Image: $IMAGE_NAME"
echo "Run with ./run.sh on Linux or ./run.ps1 on Windows"
