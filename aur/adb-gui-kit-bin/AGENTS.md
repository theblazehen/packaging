# Package: adb-gui-kit-bin

## Upstream
- Repository: https://github.com/Drenzzz/ADBKit
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
- Uses the system-tools AppImage and system android-tools and scrcpy packages
- Requires GTK4 and WebKitGTK 6.0; the old GTK3 and bundled bin/linux layout no longer apply
- Arch version 2.0.0beta4 maps to upstream tag v2.0.0-beta4; nvchecker normalizes the beta suffix
- Installs to /opt/adb-gui-kit-bin
- Smoke-test the installed launcher in a graphical session; --help is not a supported CLI smoke contract
- Keep WebKit sandboxing enabled. Nested-container GUI checks need namespace/proc mount support in the test environment, not sandbox-disabling flags in the package
