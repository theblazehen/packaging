# Package: blivet-gui

## Upstream
- Repository: https://github.com/storaged-project/blivet-gui
- Type: Python application (GitHub releases)
- Version tracking: GitHub tags

## Update Detection
```bash
curl -sL https://api.github.com/repos/storaged-project/blivet-gui/releases/latest | jq -r .tag_name
```

## Update Instructions
1. Update `pkgver` in PKGBUILD
2. Run `updpkgsums`
3. Build with `makepkg -sf`
4. Test install
5. Regenerate `.SRCINFO`

## Notes
- GUI tool for storage configuration using blivet library
- Requires python-blivet from AUR
