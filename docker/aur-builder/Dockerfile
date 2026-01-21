# AUR Builder Container with OpenCode
# Pre-configured for autonomous AUR package updates

FROM archlinux:latest

# Install base packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
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
        && \
    pacman -Scc --noconfirm

RUN curl -fsSL https://opencode.ai/install | bash

# Create builder user (non-root for makepkg)
RUN useradd -m builder && \
    echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Setup SSH for AUR
RUN mkdir -p /home/builder/.ssh && \
    chmod 700 /home/builder/.ssh && \
    echo -e "Host aur.archlinux.org\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null\n\tIdentityFile ~/.ssh/aur_key\n\tUser aur" > /home/builder/.ssh/config && \
    chmod 600 /home/builder/.ssh/config && \
    chown -R builder:builder /home/builder/.ssh

# Setup OpenCode config directory
RUN mkdir -p /home/builder/.config/opencode && \
    chown -R builder:builder /home/builder/.config

# Copy OpenCode settings (auto-approve tools)
COPY --chown=builder:builder opencode-config.json /home/builder/.config/opencode/config.json

# Setup git config for commits
RUN git config --system user.name "AUR Bot" && \
    git config --system user.email "aur-bot@users.noreply.github.com" && \
    git config --system --add safe.directory '*'

# Entrypoint script for runtime setup
COPY --chmod=755 entrypoint.sh /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
