# Package: clawd.bot

## Upstream
- Repository: https://github.com/clawdbot/clawdbot
- Type: Docker image with patches

## Our Changes
- Dockerfile for containerization
- Entry point modifications for Docker
- GitHub workflow for automated builds
- Additional CLI tools (gh, uv/uvx)
- Chromium and fonts for sandbox
- Beads task tracking for AI agents

## Build
```bash
mise setup
mise sync
mise build
mise test
```

## Update Workflow
When upstream updates:
1. `mise sync` rebases our patches
2. Resolve any conflicts in `.cache/docker/clawd.bot/`
3. `mise build` to test
4. `mise export` to save updated patches
