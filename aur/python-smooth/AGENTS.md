# Package: python-smooth

## Upstream
- Repository: https://github.com/circlemind-ai/smooth-sdk
- PyPI: https://pypi.org/project/smooth-py/
- Type: Python package (AI browser automation SDK/CLI)
- Version tracking: PyPI registry

## Update Detection
```bash
pip index versions smooth-py 2>/dev/null | head -1
```

## Update Instructions
1. Check PyPI for new version
2. Update `pkgver` in PKGBUILD
3. Run `updpkgsums`
4. Test with `makepkg -sf && makepkg -si`
5. Regenerate `.SRCINFO`
6. Commit: "python-smooth: update to <version>"

## Notes
- PyPI package name is `smooth-py`, AUR name follows `python-*` convention
- Requires Python >=3.10
- Optional `mcp` extra provides `python-fastmcp` dependency
- No license declared upstream; packaged as custom:proprietary
