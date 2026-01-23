# Package: ranger-git

## Upstream
- Repository: https://github.com/ranger/ranger
- Website: https://ranger.github.io/
- Type: Python package (VCS/git)
- Version tracking: git commits

## Update Detection
```bash
git ls-remote https://github.com/ranger/ranger.git HEAD
```

## Update Instructions
1. pkgver auto-updates from git on build
2. Run `makepkg -sf` to rebuild
3. Test with `ranger --version`
4. Regenerate `.SRCINFO` (pkgver will change)
5. Commit: "ranger-git: update to <version>"

## Smoke Test
```bash
ranger --version
ranger --help
```

## Notes
- Provides `ranger` and conflicts with the stable `ranger` package
- Many optional dependencies for file previews (see PKGBUILD)
- Python 3.14+ compatible (just needs rebuild when Python updates)
- Uses `ueberzugpp` instead of deprecated `python-ueberzug` for image previews
