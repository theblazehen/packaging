# Package: yt-beats

## Upstream
- Repository: https://github.com/krishnakanthb13/yt-beats
- Type: Python/shell application
- Version tracking: GitHub releases with `v` prefix

## Update Detection
```bash
curl -sL https://api.github.com/repos/krishnakanthb13/yt-beats/releases/latest | jq -r .tag_name
```

## Update Instructions
1. Update `pkgver` in PKGBUILD
2. Run `updpkgsums`
3. Build with `makepkg -sf`
4. Test with `yt-beats --help`
5. Regenerate `.SRCINFO`

## Notes
- Terminal music player for YouTube and local audio
- Uses yt-dlp for YouTube playback
- Requires python-textual for TUI
- Installs to /opt and symlinks to /usr/bin
