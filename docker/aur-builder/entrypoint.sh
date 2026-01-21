#!/bin/bash
set -e

if [ -n "$LLM_API_KEY" ]; then
	sed -i "s/PLACEHOLDER_API_KEY/$LLM_API_KEY/" /home/builder/.config/opencode/config.json
fi

if [ -n "$AUR_SSH_PRIVATE_KEY" ]; then
	mkdir -p ~/.ssh
	echo "$AUR_SSH_PRIVATE_KEY" >~/.ssh/aur_key
	chmod 600 ~/.ssh/aur_key
fi

if [ -n "$GIT_USER_NAME" ]; then
	git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
	git config --global user.email "$GIT_USER_EMAIL"
fi

if [ -d /workspace ] && [ "$(stat -c '%U' /workspace)" != "builder" ]; then
	sudo chown -R builder:builder /workspace 2>/dev/null || true
fi

exec "$@"
