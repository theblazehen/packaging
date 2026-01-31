# Package: tuitube-bin

## Upstream
- Repository: https://github.com/remorses/tuitube
- Type: Pre-built binary (Bun/Node compiled)
- Version tracking: GitHub releases

## Version Format
Upstream uses `tuitube@YYYYMMDDHHMM` tag format (e.g., `tuitube@202601102121`).
PKGBUILD converts this to `pkgver=YYYY.MM.DD` and `pkgrel=HHMM`.

## Update Detection
```bash
curl -s https://api.github.com/repos/remorses/tuitube/releases/latest | jq -r '.tag_name'
```

## Update Instructions
1. Check GitHub releases for new version
2. Parse tag `tuitube@YYYYMMDDHHMM` into:
   - `pkgver=YYYY.MM.DD`
   - `pkgrel=HHMM`
3. Run `updpkgsums`
4. Test with `makepkg -sf`
5. Smoke test: `tuitube --help`
6. Regenerate `.SRCINFO`
7. Commit: "tuitube-bin: update to <version>"

## Notes
- Supports both x86_64 and aarch64
- Binary is self-contained (bundled with Bun runtime)
- `options=(!strip)` is required - stripping breaks the binary
