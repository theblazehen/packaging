#!/bin/bash
set -e

# Setup AUR SSH key if provided
if [ -n "$AUR_SSH_PRIVATE_KEY" ]; then
	echo "$AUR_SSH_PRIVATE_KEY" >~/.ssh/aur_key
	chmod 600 ~/.ssh/aur_key
fi

# Setup git user if provided
if [ -n "$GIT_USER_NAME" ]; then
	git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
	git config --global user.email "$GIT_USER_EMAIL"
fi

# Ensure workspace is owned by builder
if [ -d /workspace ] && [ "$(stat -c '%U' /workspace)" != "builder" ]; then
	sudo chown -R builder:builder /workspace 2>/dev/null || true
fi

exec "$@"
