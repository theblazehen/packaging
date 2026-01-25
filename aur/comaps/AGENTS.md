# Package: comaps

## Upstream
- Repository: https://codeberg.org/comaps/comaps
- Type: C++ application (source build with many submodules)
- Version tracking: Codeberg tags

## Update Detection
Check https://codeberg.org/comaps/comaps/releases for new tags

## Update Instructions
1. Update `pkgver` in PKGBUILD (format: vYYYY.MM.DD_N)
2. Run `checksums` to update sha256sums
3. Run `srcinfo` to regenerate `.SRCINFO`
4. Run `export` to copy changes back

## CI Policy: SKIP BUILD
This package takes too long to build in CI (~30+ min). Updates are "rubber stamped":
- Version and checksums are updated
- Build is skipped (trusted upstream)
- Users build locally on install

The `build` task is a no-op in CI. Use `build-local` for actual builds.

## Notes
- Offline maps app (fork of Organic Maps)
- Very large build with many git submodules
- Requires significant disk space and build time
- Git sources use SKIP checksums (acceptable for VCS sources)
