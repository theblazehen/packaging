# Packaging Workspace

This workspace manages packaging for various distribution channels.

## Structure
- `aur/`: Arch User Repository packages
- `docker/`: Docker container images (planned)
- `nvchecker.toml`: Version checking configuration
- `.github/workflows/`: Automated update workflows

## Automation (GitHub Actions + OpenCode)

Daily automated workflow:
1. **nvchecker** detects upstream version changes
2. **OpenCode** (claude-opus-4-5) prepares updates in Arch container:
   - Updates PKGBUILD
   - Runs `updpkgsums`
   - Builds with `makepkg -sf` and observes output
   - Smoke tests the install
   - Generates `.SRCINFO`
3. Creates **PR with changelog** for human review (or Issue if build fails)
4. On PR merge, **auto-pushes to AUR**

### Secrets Required
- `LLM_PROXY_API_KEY`: OpenCode LLM access
- `AUR_SSH_PRIVATE_KEY`: SSH key for AUR push

### Manual Trigger
Run workflow manually: Actions → "AUR Package Update Check" → Run workflow

## Tools
- `makepkg`: Build Arch packages
- `updpkgsums`: Update checksums in PKGBUILD
- `namcap`: Package quality control (install if missing)
- `nvchecker`: Upstream version detection

## Global Policies
- **License**: Ensure proper SPDX identifiers
- **Security**: Don't embed secrets
- **Communication**: Use concise commit messages
