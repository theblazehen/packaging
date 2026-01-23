# AUR Package Automation

Automated AUR package updates using [OpenCode](https://opencode.ai) AI agent.

## How It Works

1. **nvchecker** detects upstream version changes daily
2. **OpenCode** updates PKGBUILDs, builds, and tests in an Arch container
3. Creates **PR** for review (or Issue if build fails)
4. On merge, **auto-pushes to AUR**

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

Actions → "AUR Package Update Check" → Run workflow
