#!/usr/bin/env bash

set -e
echo "Running container initialization.."

if [[ -n "${GIT_USER_NAME:-}" ]]; then
	echo "  - Setting git user.name to $GIT_USER_NAME"
	git config --global user.name "$GIT_USER_NAME"
fi

if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
	echo "  - Setting git user.email to $GIT_USER_EMAIL"
	git config --global user.email "$GIT_USER_EMAIL"
fi

echo "  - Disabling git credential.helper"
git config --global --unset-all credential.helper || true
git config --global credential.helper ""

# Allow only SSH-based git authentication
echo "  - Setting SSH-only git authentication"
export GIT_TERMINAL_PROMPT=0
