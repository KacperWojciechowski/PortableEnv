#!/usr/bin/env bash
set -euo pipefail

CONFIG_JSON="${1:-/tmp/repos.json}"
WORKDIR="/workspace"
GIT_USER="${GIT_USER:-}"

if [[ -z "$GIT_USER" ]]; then
	echo "ERROR: GIT_USER not set"
	exit 1
fi

if [[ ! -f "$CONFIG_JSON" ]]; then
	echo "ERROR: Repo config not found $CONFIG_JSON. Skipping..."
	exit 0
fi

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Clonning repositories defined in $CONFIG_JSON"

jq -c '.repositories[]' "$CONFIG_JSON" | while read -r repo; do
	name=$(jq -r '.name' <<<"$repo")
	url_tpl=$(jq -r '.url' <<<"$repo")
	fallback=$(jq -r '.fallback // empty' <<<"$repo")
	branch=$(jq -r '.branch // empty' <<<"$repo")

	url="${url_tpl//\$\{GIT_USER\}/$GIT_USER}"

	if [[ -d "$name/.git" ]]; then
		echo "\u2714 Repo '$name' already exists, skipping..."
		continue
	fi

	echo "\u2192 Trying to clone fork: $url"

	if git ls-remote "$url" &>/dev/null; then
		CLONE_URL="$url"
	elif [[ -n "$fallback" ]]; then
		echo "\u21AA Fork not found, using upstream"
		CLONE_URL="$fallback"
	else
		echo "\u2716 No valid repo for '$name'"
		continue
	fi

	if [[ -n "$branch" ]]; then
		git clone --branch "$branch" "$CLONE_URL" "$name"
	else
		git clone "$CLONE_URL" "$name"
	fi
done

echo "Repository cloning complete."
