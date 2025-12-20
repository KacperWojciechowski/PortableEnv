FROM archlinux:latest

# TODO: Reorganize the order of the instructions to minimize the re-building time

ARG GIT_USER

# Set the locale
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TERM=xterm-256color
ENV STARSHIP_CONFIG=/etc/starship/starship.toml

# Copy custom dependencies installer and config
COPY ../config.json /tmp/config.json
COPY container-scripts/Install_iotional.sh /tmp/install_optional.sh
RUN chmod +x /tmp/install_optional.sh

# Copy repository clone script
COPY ../repos.json /tmp/repos.json
COPY container-scripts/clone_repos.sh /tmp/clone_repos.sh
RUN chmod +x /tmp/clone_repos.sh

# Install dependencies
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
	glibc \
        base \
        base-devel \
        sudo \
        git \
        openssh \
        curl \
        wget \
        fish \
        starship \
	jq \
        ca-certificates \
        noto-fonts \
        noto-fonts-emoji && \
    pacman -Scc --noconfirm

# Set locale
RUN localedef -i en_US -f UTF-8 en_US.UTF-8 || true

# Create dev user
ARG USERNAME=Dev
ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} ${USERNAME} && \
    useradd -m -u ${UID} -g ${GID} -s /usr/bin/fish ${USERNAME}

# Passwordless sudo
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Install optional packages from config.json
RUN /tmp/install_optional.sh /tmp/config.json

# Clone the repositories provided by the user
RUN --mount=type=ssh /tmp/clone_repos.sh /tmp/repos.js

# SSH setup via agent forwarding
RUN mkdir -p /home/$USERNAME && \
    mkdir -p /home/$USERNAME/.ssh && \
    chmod 700 /home/${USERNAME}/.ssh && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh

RUN echo -e "Host *\n\tStrictHostKeyChecking accept-new\n" > /etc/ssh/ssh_config
RUN ssh-keyscan github.com > ~/.ssh/known_hosts

# Fish + starship terminal config
RUN mkdir -p /etc/fish/conf.d
COPY fish-starship.fish /etc/fish/conf.d/starship.fish
COPY starship.toml /etc/starship/starship.toml

# Startup script
COPY container-scripts/ /opt/container-scripts/
RUN chmod +x /opt/container-scripts/*.sh

# Switch user
USER ${USERNAME}
WORKDIR /workspace

# Entrypoint
ENTRYPOINT ["/usr/bin/fish", "-lc", "/opt/container-scripts/init.sh; exec fish"]
