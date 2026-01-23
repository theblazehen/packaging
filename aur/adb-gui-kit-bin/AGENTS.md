# Package: adb-gui-kit-bin

## Upstream
- Repository: https://github.com/Drenzzz/adb-gui-kit
- Type: Binary (GitHub releases)
- Version tracking: GitHub releases

## Update Detection
```bash
curl -sL https://api.github.com/repos/Drenzzz/adb-gui-kit/releases/latest | jq -r .tag_name
```

## Update Instructions
1. Update `pkgver` in PKGBUILD
2. Run `updpkgsums`
3. Build with `makepkg -sf`
4. Test install
5. Regenerate `.SRCINFO`

## Notes
- GUI for ADB and Fastboot
- Uses system android-tools package
- Installs to /opt/adb-gui-kit-bin
