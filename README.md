# Docker container-based environment

A Docker-based virtual environment made with Arch image for C, C++ and Rust development. The container uses the SSH keys from host OS, copied as Read-only when starting the container (executing `./run.sh`). Keys are not persistant in the image, and are only injected when starting the container.

# Instruction

0. \* Install Docker for your host OS, generate your SSH keys on the host OS if you don't have any yet, and add them in your GitHub account settings;
1. Create `.env` file locally in your cloned repository, with `GIT_USER_NAME` and `GIT_USER_EMAIL` variables set;
2. Run ./setup.sh
3. Run ./run.sh
4. Enjoy!
