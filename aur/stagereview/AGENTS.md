# Package: stagereview

## Upstream
- Repository: https://github.com/ReviewStage/stage-cli
- NPM: https://www.npmjs.com/package/stagereview
- Type: Node.js npm package
- Version tracking: npm registry

## Update Detection
```bash
npm view stagereview version
```

## Update Instructions
1. Check npm for new version
2. Update `pkgver` in PKGBUILD
3. Run `updpkgsums`
4. Test with `makepkg -sf && makepkg -si`
5. Regenerate `.SRCINFO`
6. Commit: "stagereview: update to <version>"

## Notes
- Native dep `better-sqlite3` may need to compile during install. The `--ignore-scripts` flag is intentionally NOT set so postinstall builds run.
