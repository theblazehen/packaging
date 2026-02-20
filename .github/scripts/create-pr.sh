#!/usr/bin/env bash
set -euo pipefail

# Create branch, commit, push, open PR with auto-merge.
# Run AFTER try-update.sh succeeds and LLM approves (or after LLM fixes).
#
# Expects: exported files already in $PKG_DIR/ (via try-update.sh or LLM)
#
# Required env:
#   PKG_DIR      - e.g. aur/kimaki
#   NEW_VERSION  - e.g. 0.4.65
#   OLD_VERSION  - e.g. 0.4.64
#   GH_TOKEN     - GitHub token
#
# Optional env:
#   LLM_REVIEW   - LLM's review summary (included in PR body)

PKG_NAME=$(basename "$PKG_DIR")
BRANCH="update/${PKG_NAME}/${NEW_VERSION}"
COMMIT_MSG="$PKG_NAME: update to $NEW_VERSION"

echo "=== Creating PR for $PKG_DIR $NEW_VERSION ==="

# Step 1: Update old_ver.json (while still on current working tree)
echo "--- Updating old_ver.json ---"
PKG_KEY="$PKG_DIR"
SAFE_NAME=$(echo "$PKG_KEY" | tr '/' '_')
VERSION_FILE="/tmp/pkg-versions/${SAFE_NAME}.json"

if [[ -f "$VERSION_FILE" ]]; then
	python3 <<PYEOF
import json

old_ver_path = '.github/nvchecker/old_ver.json'
with open(old_ver_path) as f:
    old_ver = json.load(f)

with open('$VERSION_FILE') as f:
    new_info = json.load(f)

data = old_ver.get('data', old_ver)
for pkg, info in new_info.items():
    data[pkg] = info

if 'data' in old_ver:
    old_ver['data'] = data
    with open(old_ver_path, 'w') as f:
        json.dump(old_ver, f, indent=2)
else:
    with open(old_ver_path, 'w') as f:
        json.dump(data, f, indent=2)
PYEOF
	echo "Updated old_ver.json for $PKG_KEY"
else
	echo "Warning: version file $VERSION_FILE not found, skipping old_ver.json update"
fi

# Step 2: Create feature branch FROM CURRENT STATE (preserving working tree changes)
echo "--- Creating branch $BRANCH ---"
git checkout -B "$BRANCH"

# Step 3: Stage changes
git add "$PKG_DIR/PKGBUILD" "$PKG_DIR/.SRCINFO"
git add .github/nvchecker/old_ver.json 2>/dev/null || true
git add "$PKG_DIR/" 2>/dev/null || true

# Step 4: Commit
git commit -m "$COMMIT_MSG"

# Step 5: Push
echo "--- Pushing branch ---"
git push -u origin "$BRANCH" --force

# Step 6: Build PR body and write to file (avoids quoting issues)
{
	echo "## $PKG_NAME: $OLD_VERSION → $NEW_VERSION"
	echo ""
	echo "### Changes"

	if [[ -f /tmp/changelog.txt ]]; then
		echo ""
		head -c 20000 /tmp/changelog.txt
		if [[ $(wc -c </tmp/changelog.txt) -gt 20000 ]]; then
			echo ""
			echo "*...changelog truncated...*"
		fi
	fi

	if [[ -n "${LLM_REVIEW:-}" ]]; then
		echo ""
		echo "### LLM Review"
		echo "$LLM_REVIEW"
	fi

	if [[ -f /tmp/namcap-output.txt ]] && [[ -s /tmp/namcap-output.txt ]]; then
		echo ""
		echo "### namcap output"
		echo '```'
		cat /tmp/namcap-output.txt
		echo '```'
	fi
} >/tmp/pr-body-raw.md

# Truncate PR body to stay under GitHub's 65536 char limit
MAX_BODY=60000
if [[ $(wc -c </tmp/pr-body-raw.md) -gt $MAX_BODY ]]; then
	head -c $MAX_BODY /tmp/pr-body-raw.md >/tmp/pr-body.md
	echo "" >>/tmp/pr-body.md
	echo "---" >>/tmp/pr-body.md
	echo "*PR body truncated (exceeded GitHub's 65536 char limit)*" >>/tmp/pr-body.md
else
	cp /tmp/pr-body-raw.md /tmp/pr-body.md
fi

# Step 7: Create PR with auto-merge
echo "--- Creating PR ---"
PR_URL=$(gh pr create \
	--title "$COMMIT_MSG" \
	--body-file /tmp/pr-body.md \
	--base main \
	--head "$BRANCH")

echo "Created: $PR_URL"

echo "--- Enabling auto-merge ---"
gh pr merge --auto --squash "$PR_URL" || echo "Warning: auto-merge may not be enabled on this repo"

echo "=== PR created: $PR_URL ==="
echo "$PR_URL" >/tmp/pr-url.txt
