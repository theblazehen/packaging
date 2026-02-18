#!/usr/bin/env bash
set -euo pipefail

# Mechanical version bump + build for AUR packages.
# Handles: npm, GitHub release, -git packages.
# Exits 0 on success, 1 on build failure (caller should invoke LLM).
#
# Required env:
#   PKG_DIR      - e.g. aur/kimaki
#   NEW_VERSION  - e.g. 0.4.65
#   OLD_VERSION  - e.g. 0.4.64
#
# Outputs (files):
#   /tmp/build-output.txt   - full build log
#   /tmp/namcap-output.txt  - namcap warnings
#   /tmp/update-status.txt  - "success" or "build-failed"

PKG_NAME=$(basename "$PKG_DIR")
WORKSPACE="${PWD}/.cache/${PKG_DIR}"

is_git_package() {
	[[ "$PKG_NAME" == *-git ]]
}

echo "=== Updating $PKG_DIR: $OLD_VERSION → $NEW_VERSION ==="

# Step 1: Setup workspace
echo "--- Setting up workspace ---"
mise -C "$PKG_DIR" r setup

# Step 2: Sync files to workspace
echo "--- Syncing workspace ---"
mise -C "$PKG_DIR" r sync 2>&1 || true

# Step 3: Version bump (skip for -git packages, pkgver() handles it)
if ! is_git_package; then
	echo "--- Updating pkgver to $NEW_VERSION ---"
	sed -i "s/^pkgver=.*/pkgver=$NEW_VERSION/" "$WORKSPACE/PKGBUILD"
	sed -i "s/^pkgrel=.*/pkgrel=1/" "$WORKSPACE/PKGBUILD"
fi

# Step 4: Update checksums (skip for -git packages which use SKIP)
if ! is_git_package; then
	echo "--- Updating checksums ---"
	mise -C "$PKG_DIR" r checksums 2>&1
fi

# Step 5: Build
echo "--- Building package ---"
BUILD_EXIT=0
mise -C "$PKG_DIR" r build 2>&1 | tee /tmp/build-output.txt || BUILD_EXIT=$?

if [[ $BUILD_EXIT -ne 0 ]]; then
	echo "build-failed" >/tmp/update-status.txt
	echo "--- Build FAILED (exit $BUILD_EXIT) ---"
	echo "" >/tmp/namcap-output.txt
	exit 1
fi

# Step 6: Run namcap
echo "--- Running namcap ---"
{
	namcap "$WORKSPACE/PKGBUILD" 2>&1 || true
	PKG_FILE=$(find "$WORKSPACE" -maxdepth 1 -name '*.pkg.tar*' ! -name '*-debug-*' -print -quit 2>/dev/null)
	if [[ -n "${PKG_FILE:-}" ]]; then
		namcap "$PKG_FILE" 2>&1 || true
	fi
} | tee /tmp/namcap-output.txt

# Step 7: Generate .SRCINFO
echo "--- Generating .SRCINFO ---"
mise -C "$PKG_DIR" r srcinfo 2>&1

# Step 8: Export back to package dir
echo "--- Exporting to package dir ---"
mise -C "$PKG_DIR" r export 2>&1

echo "success" >/tmp/update-status.txt
echo "=== Build succeeded ==="
