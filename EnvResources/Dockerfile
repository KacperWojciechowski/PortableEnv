FROM archlinux:latest

ARG GIT_USER

# Set the locale
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TERM=xterm-256color
ENV STARSHIP_CONFIG=/etc/starship/starship.toml

# Instal basic ddependencies for the system
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
    noto-fonts-emoji \
    unzip \
    zip \
    tree \
    vim \
    neovim

# Set locale
RUN localedef -i en_US -f UTF-8 en_US.UTF-8 || true

# Create dev user
ARG USERNAME=Dev
ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} ${USERNAME} && \
    useradd -m -u ${UID} -g ${GID} -s /usr/bin/fish ${USERNAME}

RUN echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# SSH setup via agent forwarding
RUN mkdir -p /home/$USERNAME && \
    mkdir -p /home/$USERNAME/.ssh && \
    chmod 700 /home/$USERNAME/.ssh && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh

RUN echo -e "Host *\n\tStrictHostKeyChecking accept-new\n" > /etc/ssh/ssh_config
RUN ssh-keyscan github.com > ~/.ssh/known_hosts

# Copy and execute configuration scripts
RUN mkdir -p /etc/fish/conf.d

COPY config.json /tmp/config.json
COPY repos.json /tmp/repos.json
COPY EnvResources/container-scripts/install_optional.sh /tmp/install_optional.sh
COPY EnvResources/container-scripts/clone_repos.sh /tmp/clone_repos.sh
COPY EnvResources/fish-starship.fish /etc/fish/conf.d/starship.fish
COPY EnvResources/starship.toml /etc/starship/starship.toml

RUN chmod +x /tmp/*.sh

RUN /tmp/install_optional.sh /tmp/config.json
RUN --mount=type=ssh /tmp/clone_repos.sh /tmp/repos.json

# Switch user
USER ${USERNAME}
WORKDIR /workspace

# Entrypoint
ENTRYPOINT ["/usr/bin/fish", "-lc", "/opt/container-scripts/init.sh; exec fish"]
