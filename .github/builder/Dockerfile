# AUR Builder Container with OpenCode
# Pre-configured for autonomous AUR package updates

FROM archlinux:latest

# Install all packages from Arch repos
# Includes tools + all depends/makedepends for managed AUR packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        # Build tools
        base-devel \
        git \
        openssh \
        npm \
        pacman-contrib \
        jq \
        github-cli \
        unzip \
        namcap \
        curl \
        sudo \
        mise \
        jujutsu \
        # Language toolchains (makedepends)
        go \
        cargo \
        python-build \
        python-installer \
        python-poetry-core \
        python-setuptools \
        cabal-install \
        ghc \
        # Python depends
        python-pip \
        python-pydantic \
        python-aiohttp \
        python-deprecated \
        python-cairo \
        python-gobject \
        python-aiohttp-retry \
        python-mpv-jsonipc \
        python-requests \
        python-textual \
        # X11/Wayland libs
        libxcursor \
        libxfixes \
        libxkbcommon \
        wayland \
        libxkbcommon-x11 \
        libx11 \
        libxcb \
        libglvnd \
        libxft \
        libxinerama \
        imlib2 \
        # GTK/desktop libs
        gtk3 \
        glib2 \
        cairo \
        gdk-pixbuf2 \
        libnotify \
        adwaita-icon-theme \
        hicolor-icon-theme \
        # Runtime deps
        dbus \
        openssl \
        xz \
        bzip2 \
        jre-openjdk-headless \
        android-tools \
        yt-dlp \
        && \
    pacman -Scc --noconfirm

# Create builder user with UID 1001 (GitHub Actions runner UID)
RUN useradd -m -u 1001 builder && \
    echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Install OpenCode (not in Arch repos)
RUN curl -fsSL https://opencode.ai/install | bash && \
    mv /root/.opencode/bin/opencode /usr/local/bin/opencode

# Install yay (AUR helper) as builder user
USER builder
WORKDIR /tmp
RUN git clone https://aur.archlinux.org/yay-bin.git && \
    cd yay-bin && \
    makepkg -si --noconfirm && \
    cd .. && rm -rf yay-bin

# Install AUR-only dependencies for managed packages
RUN yay -S --noconfirm --needed \
        python-blivet \
        python-nanoid \
        python-pid

USER root

# Setup SSH for AUR
RUN mkdir -p /home/builder/.ssh && \
    chmod 700 /home/builder/.ssh && \
    echo -e "Host aur.archlinux.org\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null\n\tIdentityFile ~/.ssh/aur_key\n\tUser aur" > /home/builder/.ssh/config && \
    chmod 600 /home/builder/.ssh/config && \
    chown -R builder:builder /home/builder/.ssh

# Setup OpenCode config directories
RUN mkdir -p /home/builder/.config/opencode /root/.config/opencode && \
    chown -R builder:builder /home/builder/.config

COPY --chown=builder:builder opencode-config.json /home/builder/.config/opencode/opencode.json
COPY opencode-config.json /root/.config/opencode/opencode.json

# Setup git config for commits
RUN git config --system user.name "AUR Bot" && \
    git config --system user.email "aur-bot@users.noreply.github.com" && \
    git config --system --add safe.directory '*'

# Entrypoint script for runtime setup
COPY --chmod=755 entrypoint.sh /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
