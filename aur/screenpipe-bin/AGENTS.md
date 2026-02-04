# Package: screenpipe-bin

## Upstream
- Repository: https://github.com/screenpipe/screenpipe
- Type: Pre-built Rust binary
- Version tracking: GitHub releases (v* tags, not mcp-v* tags)

## Update Detection
```bash
curl -s https://api.github.com/repos/screenpipe/screenpipe/releases | jq -r '[.[] | select(.tag_name | startswith("v"))][0].tag_name'
```

## Update Instructions
1. Check GitHub releases for new version (ignore mcp-v* releases)
2. Update `pkgver` in PKGBUILD
3. Run `updpkgsums`
4. Test with `makepkg -sf`
5. Smoke test: `screenpipe --help`
6. Regenerate `.SRCINFO`
7. Commit: "screenpipe-bin: update to <version>"

## Notes
- Binary releases are at `screenpipe-{version}-x86_64-unknown-linux-gnu.tar.gz`
- The repo has two release streams: main app (v*) and MCP server (mcp-v*)
- Only track the main app releases (v* prefix)
- Dependencies: glibc, gcc-libs, libxcb, dbus, openssl, alsa-lib, xz, xdotool
