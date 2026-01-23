# AUR Packaging Directory

This directory contains individual AUR packages managed by this workspace.

## Structure

Each subdirectory corresponds to an AUR package:
```
aur/<package-name>/
├── .aur-files      # Manifest of files to push to AUR
├── .aur-remote     # AUR git remote URL
├── mise.toml       # Package-specific mise config
├── AGENTS.md       # Package-specific instructions
├── PKGBUILD        # Arch package build script
├── .SRCINFO        # Generated package metadata
└── [extra files]   # .install, .service, patches/, etc.
```

## .aur-files Manifest

Each package has a `.aur-files` file listing what gets pushed to AUR.

**Format:**
- One file/directory per line
- Comments start with `#`
- Empty lines are ignored
- Files NOT listed stay local (mise.toml, AGENTS.md, .aur-remote, .aur-files)

**Default content:**
```
PKGBUILD
.SRCINFO
```

**With extra files (example: yacy):**
```
PKGBUILD
.SRCINFO
yacy.install
yacy.service
yacy.sh
```

**When to add entries:**
- `.install` files (pre/post install hooks)
- `.service` files (systemd units)
- Helper scripts sourced by PKGBUILD
- `patches/` directory if upstream needs patching
- `.desktop` files for GUI apps

**Push behavior:**
- CI and `mise run aur-push` read from `.aur-files`
- Missing files cause immediate failure (fail-fast)
- Files not in `.aur-files` are never pushed to AUR

## Workflow for Updating Packages

1. **Detection**: Check `AGENTS.md` in each package directory for update instructions
2. **Update**:
   - Update `pkgver` in PKGBUILD
   - Run `updpkgsums`
   - Build with `makepkg -sf`
   - Test install with `makepkg -si`
   - Generate `.SRCINFO` with `makepkg --printsrcinfo > .SRCINFO`
3. **Commit**: Use standard commit message format
4. **Push**: Merging to main auto-pushes files in `.aur-files` to AUR

## New Package Creation

1. Create directory `aur/<package-name>`
2. Create `PKGBUILD` following Arch Wiki guidelines
3. Create `AGENTS.md` with specific update instructions
4. Create `.aur-files` with at minimum:
   ```
   PKGBUILD
   .SRCINFO
   ```
5. Create `.aur-remote` with: `ssh://aur@aur.archlinux.org/<package-name>.git`
6. Create `mise.toml` (copy from existing package)
7. `makepkg --printsrcinfo > .SRCINFO`

## Notes

- **Node.js Packages**: Follow guidelines in `aur/promptfoo/PKGBUILD` (cleanup steps are critical)
- **Go Packages**: See `aur/lazybeads-git/PKGBUILD` for proper build flags
- **-git Packages**: Must include `pkgver()` function
