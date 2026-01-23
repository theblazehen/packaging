# Package: comaps

## Upstream
- Repository: https://codeberg.org/comaps/comaps
- Type: C++ application (source build with many submodules)
- Version tracking: Codeberg tags

## Update Detection
Check https://codeberg.org/comaps/comaps/releases for new tags

## Update Instructions
1. Update `pkgver` in PKGBUILD (format: vYYYY.MM.DD_N)
2. Build with `makepkg -sf` (requires 5+ GiB disk space)
3. Test the application
4. Regenerate `.SRCINFO`

## Notes
- Offline maps app (fork of Organic Maps)
- Very large build with many git submodules
- Requires significant disk space and build time
- Git sources use SKIP checksums (acceptable for VCS sources)
