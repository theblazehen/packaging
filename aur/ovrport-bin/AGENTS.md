# Package: ovrport-bin

## Upstream
- Repository: https://github.com/ovrport/app
- Type: Pre-built Compose Multiplatform desktop app (bundles JRE)
- Version tracking: GitHub releases

## Update Detection
```bash
git ls-remote --tags --refs https://github.com/ovrport/app.git | tail -1
```

## Update Instructions
1. Check GitHub releases for new version
2. Update `pkgver` in PKGBUILD
3. Run `updpkgsums`
4. Test with `makepkg -si`
5. Regenerate `.SRCINFO`
6. Commit: "ovrport-bin: update to <version>"

## Notes
- The desktop-linux.zip contains a self-contained app with bundled JRE
- Extracts to `app/overport/` with `bin/overport` as the main executable
- Icon at `lib/overport.png`
