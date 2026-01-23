# Package: slackdump-bin

## Upstream
- Repository: https://github.com/rusq/slackdump
- Type: Binary (GitHub releases)
- Version tracking: GitHub releases

## Update Detection
```bash
curl -sL https://api.github.com/repos/rusq/slackdump/releases/latest | jq -r .tag_name
```

## Update Instructions
1. Update `pkgver` in PKGBUILD
2. Run `updpkgsums`
3. Build with `makepkg -sf`
4. Test with `slackdump --version`
5. Regenerate `.SRCINFO`

## Notes
- Pre-built Go binary for multiple architectures
- Saves Slack messages, threads, files locally
- Uses b2sums for checksums
