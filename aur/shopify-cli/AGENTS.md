# Package: shopify-cli

## Upstream
- Repository: https://github.com/Shopify/cli
- NPM: https://www.npmjs.com/package/@shopify/cli
- Type: Node.js npm package
- Version tracking: npm registry

## Update Detection
```bash
npm view @shopify/cli version
```

## Update Instructions
1. Check npm for new version
2. Update `pkgver` in PKGBUILD
3. Run `updpkgsums`
4. Test with `makepkg -sf && makepkg -si`
5. Verify: `shopify version`
6. Regenerate `.SRCINFO`
7. Commit: "shopify-cli: update to <version>"

## Notes
- Scoped npm package (`@shopify/cli`)
- Provides `shopify` binary
- Used to build apps, themes, and extensions for the Shopify platform
