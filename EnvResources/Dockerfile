#syntax=docker/dockerfile:1.6

FROM archlinux:latest

# Set the locale
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TERM=xterm-256color
ENV STARSHIP_CONFIG=/etc/starship/starship.toml

# Install basic dependencies for the system
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
    neovim \
    openssh

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

# Install development dependencies
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    clang \
    cmake \
    ninja \
    gdb \
    valgrind \
    ruby \
    boost \
    gtest \
    qt6-base \
    arm-none-eabi-gcc \
    openocd \
    stlink \
    rust

RUN gem install ceedling

# Copy and execute configuration scripts
RUN mkdir -p /etc/fish/conf.d
RUN mkdir -p /opt/container-scripts

COPY EnvResources/init.sh /opt/container-scripts/init.sh
COPY EnvResources/fish-starship.fish /etc/fish/conf.d/starship.fish
COPY EnvResources/starship.toml /etc/starship/starship.toml

RUN chmod +x /opt/container-scripts/init.sh

# Switch user
USER ${USERNAME}
WORKDIR /workspace

# Entrypoint
ENTRYPOINT ["/usr/bin/fish", "-lc", "/opt/container-scripts/init.sh; exec fish"]
