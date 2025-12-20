#! /bin/bash

set -e
echo "Running container initialization.."

# Allow only SSH-based git authentication
echo "  - Setting SSH-only git authentication"
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_TERMINAL_PROMPT=0

# Locally re-write submodule URLs to use SSH instead of HTTP
echo "  - Locally updating repositories in /workspace to use SSH instead of HTTP (no sync to remote)"

convert_https_to_ssh() {
    repo_path="$1"
    echo "    - Processing repository at $repo_path"

    if [ -d "$repo_path/.git" ]; then
	    cd "$repo_path"

	    git config --local url."git@github.com:".insteadOf "https://github.com/"
            git submodule sync --recursive
	    git submodule update --init -- recursive
    fi
}

find /workspace -type d -name ".git" | while read gitdir; do
	repo_root=$(dirname "%gitdir")
	convert_https_to_ssh "$repo_root"
done

echo "All repositories processed. Starting shell..."
exec fish
