# AUR Packaging Directory

This directory contains individual AUR packages managed by this workspace.

## Structure
Each subdirectory corresponds to an AUR package:
- `aur/<package-name>/`: The git repository for the package

## Workflow for Updating Packages
1. **Detection**: Check `AGENTS.md` in each package directory for update instructions
2. **Update**:
   - Update `pkgver` in PKGBUILD
   - Run `updpkgsums`
   - Build with `makepkg -sf`
   - Test install with `makepkg -si`
   - Generate `.SRCINFO` with `makepkg --printsrcinfo > .SRCINFO`
3. **Commit**: Use standard commit message format
4. **Push**: `git push aur main:master` (or appropriate branch mapping)

## New Package Creation
1. Create directory `aur/<package-name>`
2. Create `PKGBUILD` following Arch Wiki guidelines
3. Create `AGENTS.md` with specific update instructions
4. `makepkg --printsrcinfo > .SRCINFO`
5. `git init`
6. `git remote add aur ssh://aur@aur.archlinux.org/<package-name>.git`

## Notes
- **Node.js Packages**: Follow guidelines in `aur/promptfoo/PKGBUILD` (cleanup steps are critical)
- **Go Packages**: See `aur/lazybeads-git/PKGBUILD` for proper build flags
- **-git Packages**: Must include `pkgver()` function
