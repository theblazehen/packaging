# Package: scrapfetch-git

## Upstream
- Repository: https://github.com/amodi444/scrapfetch
- Type: C program (VCS/git)
- Version tracking: git commits

## Update Detection
```bash
git ls-remote https://github.com/amodi444/scrapfetch.git HEAD
```

## Update Instructions
1. pkgver auto-updates from git on build
2. Run `makepkg -sf` to rebuild
3. Test install with `makepkg -si`
4. Regenerate `.SRCINFO` (pkgver will change)
5. Commit: "scrapfetch-git: update to r<N>.<hash>"

## Notes
- Simple C neofetch-like tool
- Installs to /usr/bin/scrapfetch
- No runtime dependencies beyond glibc
