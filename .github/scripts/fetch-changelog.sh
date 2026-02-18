#!/usr/bin/env bash
set -eo pipefail

# Fetch real upstream changelog for a package update.
# Tries multiple sources: GitHub releases, npm, git log.
#
# Required env:
#   PKG_DIR      - e.g. aur/kimaki
#   NEW_VERSION  - e.g. 0.4.65
#   OLD_VERSION  - e.g. 0.4.64
#   GH_TOKEN     - GitHub token for API calls
#
# Output: /tmp/changelog.txt

PKG_NAME=$(basename "$PKG_DIR")
AGENTS_MD="$PKG_DIR/AGENTS.md"
CHANGELOG="/tmp/changelog.txt"

>"$CHANGELOG"

get_github_repo() {
	if [[ -f "$AGENTS_MD" ]]; then
		grep -oP 'https://github\.com/\K[^/]+/[^\s)]+' "$AGENTS_MD" | head -1 | sed 's/[[:space:]]*$//'
	fi
}

get_npm_name() {
	local section_found=0
	while IFS= read -r line; do
		if [[ "$line" == "[\"$PKG_DIR\"]" ]]; then
			section_found=1
			continue
		fi
		if [[ $section_found -eq 1 ]]; then
			if [[ "$line" == \[* ]]; then
				break
			fi
			if [[ "$line" =~ ^npm\ *=\ *\"(.+)\" ]]; then
				echo "${BASH_REMATCH[1]}"
				return 0
			fi
		fi
	done <nvchecker.toml
	return 0
}

GITHUB_REPO=$(get_github_repo || true)
NPM_NAME=$(get_npm_name || true)

echo "# Upstream Changes: $PKG_NAME $OLD_VERSION → $NEW_VERSION" >>"$CHANGELOG"
echo "" >>"$CHANGELOG"

if [[ -n "${GITHUB_REPO:-}" ]]; then
	echo "## GitHub Release" >>"$CHANGELOG"

	RELEASE_BODY=""
	for prefix in "v" ""; do
		TAG="${prefix}${NEW_VERSION}"
		RELEASE_BODY=$(gh api "repos/$GITHUB_REPO/releases/tags/$TAG" --jq '.body // empty' 2>/dev/null || true)
		if [[ -n "$RELEASE_BODY" ]]; then
			echo "**Tag: $TAG**" >>"$CHANGELOG"
			echo "" >>"$CHANGELOG"
			echo "$RELEASE_BODY" >>"$CHANGELOG"
			break
		fi
	done

	if [[ -z "$RELEASE_BODY" ]]; then
		if [[ "$PKG_NAME" == *-git ]]; then
			echo "### Recent commits" >>"$CHANGELOG"
			gh api "repos/$GITHUB_REPO/commits?per_page=20" \
				--jq '.[] | "- " + .sha[0:7] + " " + (.commit.message | split("\n")[0])' \
				2>/dev/null >>"$CHANGELOG" || echo "(could not fetch commits)" >>"$CHANGELOG"
		else
			COMPARE=""
			for old_prefix in "v" ""; do
				for new_prefix in "v" ""; do
					COMPARE=$(gh api "repos/$GITHUB_REPO/compare/${old_prefix}${OLD_VERSION}...${new_prefix}${NEW_VERSION}" \
						--jq '.commits[] | "- " + .sha[0:7] + " " + (.commit.message | split("\n")[0])' \
						2>/dev/null || true)
					if [[ -n "$COMPARE" ]]; then
						echo "### Commits ($OLD_VERSION → $NEW_VERSION)" >>"$CHANGELOG"
						echo "$COMPARE" >>"$CHANGELOG"
						break 2
					fi
				done
			done
			if [[ -z "${COMPARE:-}" ]]; then
				echo "(no release notes or commit comparison available)" >>"$CHANGELOG"
			fi
		fi
	fi
	echo "" >>"$CHANGELOG"
fi

if [[ -n "${NPM_NAME:-}" ]]; then
	echo "## npm" >>"$CHANGELOG"
	echo "Package: $NPM_NAME" >>"$CHANGELOG"
	echo "https://www.npmjs.com/package/$NPM_NAME/v/$NEW_VERSION" >>"$CHANGELOG"
	echo "" >>"$CHANGELOG"
fi

echo "---" >>"$CHANGELOG"
echo "Changelog fetched at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$CHANGELOG"

echo "=== Changelog written to $CHANGELOG ==="
cat "$CHANGELOG"
