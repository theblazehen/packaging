# Package: komac

## Upstream
- Repository: https://github.com/russellbanks/Komac
- Type: Rust application (source build)
- Version tracking: GitHub releases

## Update Detection
```bash
curl -sL https://api.github.com/repos/russellbanks/Komac/releases/latest | jq -r .tag_name
```

## Update Instructions
1. Update `pkgver` in PKGBUILD
2. Run `updpkgsums`
3. Build with `makepkg -sf` (requires Rust toolchain)
4. Test with `komac --version`
5. Regenerate `.SRCINFO`

## Notes
- WinGet manifest creator tool
- Rust build, may take a while
- Uses cargo fetch --locked for reproducibility
