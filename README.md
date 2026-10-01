# AUR Package Automation

Automated AUR package updates using [OpenCode](https://opencode.ai) AI agent.

## How It Works

1. **nvchecker** detects upstream version changes daily
2. **OpenCode** updates PKGBUILDs, builds, and tests in an Arch container
3. Creates **PR** for review (or Issue if build fails)
4. On merge, package changes pushed to `main` are built in an Arch container before publishing to AUR

## Publishing to AUR

A push to `main` that changes files under `aur/` builds every affected package as the non-root builder user (UID 1001). The workflow installs AUR-only dependencies with `yay`, runs `makepkg`, and regenerates `.SRCINFO` from the same recipe. **No package is published unless all affected builds succeed.**

Each package's `.aur-files` manifest is authoritative: blank rows and comments are ignored, listed files are exported, and previously tracked AUR files no longer listed are removed. The exporter preserves `.git` and unrelated untracked build outputs. A missing manifest source file fails before the destination is changed.

The October 2026 comment fixes add Ranger's optional `xclip` dependency, correct Blivet GUI's build metadata and declare its required D-Bus/BlockDev runtime dependencies. OpenChamber is rebuilt with its self-contained npm installation, and manifest export removes stale maintenance-only files from AUR.

## Setup

### GitHub Secrets (required)

| Secret | Description |
|--------|-------------|
| `LLM_PROXY_API_KEY` | API key for your OpenAI-compatible LLM provider |
| `AUR_SSH_PRIVATE_KEY` | SSH private key registered with AUR |

### GitHub Variables (required)

| Variable | Description | Example |
|----------|-------------|---------|
| `LLM_PROXY_URL` | Base URL for LLM API | `https://api.openai.com/v1` |
| `LLM_MODEL` | Model identifier | `gpt-4o` or `anthropic/claude-sonnet-4-20250514` |

### Adding a New Package

See [AGENTS.md](AGENTS.md) for detailed instructions.

## Manual Trigger

Actions → **"Package Updates"** → Run workflow for daily checks or a selected package.

Actions → **"Push to AUR"** → Run workflow and provide the space-separated package list to build and publish explicitly.
