# Package: caire

## Upstream
- Repository: https://github.com/esimov/caire
- Type: Go application (source build)
- Version tracking: GitHub tags with `v` prefix

## Update Detection
```bash
curl -sL https://api.github.com/repos/esimov/caire/tags | jq -r '.[0].name'
```

## Update Instructions
1. Update `pkgver` in PKGBUILD
2. Run `updpkgsums`
3. Build with `makepkg -sf` (requires Go toolchain)
4. Test with `caire -h`
5. Regenerate `.SRCINFO`

## Notes
- Content-aware image resizing using Seam Carving algorithm
- Go build with trimpath flags for reproducibility
- Requires X11/Wayland libraries for GUI features
