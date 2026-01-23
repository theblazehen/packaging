# Packaging Infrastructure Plan

## Overview

A unified packaging infrastructure for managing AUR packages and Docker images, featuring:
- **mise** for task orchestration and dependency management
- **jj** for patch/change management on all upstream git repos
- **nvchecker** for version/update detection
- **OpenCode** for intelligent updates, conflict resolution, and PR creation

## Design Principles

1. **Unified workflow** - Same jj-based flow for Docker and AUR packages
2. **Minimal repo bloat** - Upstream source not stored, only patches/changes
3. **Full context for AI** - Pre-gather all info before OpenCode runs
4. **Auditable changes** - Patches committed as files, reviewable in PRs
5. **Cached workspaces** - No re-cloning on every CI run

---

## Directory Structure

```
packaging/
├── mise.toml                          # Root monorepo config
├── nvchecker.toml                     # All version tracking
├── AGENTS.md                          # Repo-level instructions
├── README.md
│
├── .mise/
│   └── tasks/                         # Shared executable scripts
│       ├── setup-workspace            # Clone upstream, init jj, apply patches
│       ├── sync-upstream              # Fetch upstream, rebase patches
│       ├── export-patches             # jj commits → patch files
│       ├── gather-context             # Collect all info for OpenCode
│       └── aur-push                   # Push to AUR (PKGBUILD + .SRCINFO only)
│
├── .cache/                            # gitignored - jj workspaces
│   ├── docker/
│   │   └── clawd.bot/                 # jj workspace for docker build
│   └── aur/
│       └── promptfoo/                 # jj workspace tracking AUR remote
│
├── docker/
│   └── <package>/
│       ├── mise.toml                  # Package tasks & config
│       ├── .upstream                  # Upstream git URL
│       ├── .upstream-ref              # Upstream commit we're based on
│       ├── .registries                # Docker registries (one per line)
│       ├── patches/                   # Our changes as patch files
│       │   ├── 0001-add-dockerfile.patch
│       │   └── 0002-fix-entry.patch
│       └── AGENTS.md                  # Package-specific instructions
│
├── aur/
│   └── <package>/
│       ├── mise.toml                  # Package tasks & config
│       ├── .aur-remote                # "ssh://aur@aur.archlinux.org/<pkg>.git"
│       ├── .upstream                  # Optional: app upstream for version tracking
│       ├── .upstream-ref              # Optional: for -git packages
│       ├── PKGBUILD
│       ├── .SRCINFO
│       ├── patches/                   # Optional: if patching AUR history
│       └── AGENTS.md                  # NOT pushed to AUR
│
└── .github/
    ├── nvchecker/
    │   └── old_ver.json               # Version state
    └── workflows/
        ├── check-updates.yml          # Main update workflow
        ├── docker-push.yml            # Push images on merge
        └── aur-push.yml               # Push to AUR on merge
```

---

## Component Specifications

### 1. nvchecker.toml

Single source of truth for all version tracking. Namespaced by package type.

```toml
[__config__]
oldver = ".github/nvchecker/old_ver.json"
newver = ".github/nvchecker/new_ver.json"

# ============ Docker packages ============
# Track git commits (we patch the source)

[docker/clawd.bot]
source = "git"
git = "https://github.com/clawdbot/clawdbot.git"
use_commit = true

[docker/llm-relay]
source = "git"
git = "https://github.com/example/llm-relay.git"
use_commit = true

# ============ AUR packages ============
# Track releases/versions (we package, not patch)

[aur/promptfoo]
source = "npm"
npm = "promptfoo"

[aur/kimaki]
source = "npm"
npm = "kimaki"

[aur/ccstatusline]
source = "npm"
npm = "ccstatusline"

[aur/blender-mcp-git]
source = "git"
git = "https://github.com/ahujasid/blender-mcp.git"
use_commit = true

[aur/bdui-bin]
source = "github"
github = "assimelha/bdui"
use_latest_release = true

# Same app, different targets
[aur/clawd.bot-bin]
source = "github"
github = "clawdbot/clawdbot"
use_latest_release = true
prefix = "v"
```

---

### 2. Root mise.toml

```toml
[settings]
experimental_monorepo_root = true

[tools]
jj = "latest"
usage = "latest"

[env]
PACKAGING_ROOT = "{{config_root}}"
CACHE_DIR = "{{config_root}}/.cache"

[tasks.setup-all]
description = "Setup all package workspaces"
run = "mise //...:setup"

[tasks.sync-all]
description = "Sync all upstreams"
run = "mise //...:sync"

[tasks.list]
description = "List all packages"
run = '''
#!/usr/bin/env bash
echo "=== Docker packages ==="
for d in docker/*/; do echo "  ${d%/}"; done 2>/dev/null || echo "  (none)"
echo ""
echo "=== AUR packages ==="
for d in aur/*/; do echo "  ${d%/}"; done 2>/dev/null || echo "  (none)"
'''
```

---

### 3. Per-Package mise.toml Templates

#### Docker Package Template (docker/<pkg>/mise.toml)

```toml
[env]
PKG_NAME = "<package-name>"
PKG_TYPE = "docker"
PKG_DIR = "{{config_root}}"
UPSTREAM = "{{exec(command='cat .upstream 2>/dev/null || echo \"\"')}}"
UPSTREAM_REF = "{{exec(command='cat .upstream-ref 2>/dev/null || echo \"\"')}}"
REGISTRIES = "{{exec(command='cat .registries 2>/dev/null || echo \"\"')}}"
WORKSPACE = "{{env.CACHE_DIR}}/docker/<package-name>"

[tools]
jj = "latest"

[tasks.setup]
description = "Initialize jj workspace from upstream"
run = "{{env.PACKAGING_ROOT}}/.mise/tasks/setup-workspace"

[tasks.sync]
description = "Fetch upstream and rebase patches"
depends = ["setup"]
run = "{{env.PACKAGING_ROOT}}/.mise/tasks/sync-upstream"

[tasks.export]
description = "Export jj commits as patch files"
run = "{{env.PACKAGING_ROOT}}/.mise/tasks/export-patches"

[tasks.build]
description = "Build Docker image"
run = "docker build -t $PKG_NAME:local $WORKSPACE"

[tasks.test]
description = "Test Docker image"
run = '''
#!/usr/bin/env bash
docker run --rm $PKG_NAME:local --version 2>/dev/null || \
docker run --rm $PKG_NAME:local --help 2>/dev/null || \
echo "Basic run test passed"
'''

[tasks.push]
description = "Push to all registries"
run = '''
#!/usr/bin/env bash
set -euo pipefail
VERSION=${VERSION:-latest}
while IFS= read -r registry; do
  [[ -z "$registry" ]] && continue
  echo "Pushing to $registry:$VERSION"
  docker tag $PKG_NAME:local "$registry:$VERSION"
  docker push "$registry:$VERSION"
done < "$PKG_DIR/.registries"
'''

[tasks.gather-context]
description = "Gather all context for OpenCode"
run = "{{env.PACKAGING_ROOT}}/.mise/tasks/gather-context"
```

#### AUR Package Template (aur/<pkg>/mise.toml)

```toml
[env]
PKG_NAME = "<package-name>"
PKG_TYPE = "aur"
PKG_DIR = "{{config_root}}"
AUR_REMOTE = "{{exec(command='cat .aur-remote 2>/dev/null || echo \"\"')}}"
WORKSPACE = "{{env.CACHE_DIR}}/aur/<package-name>"

[tools]
jj = "latest"

[tasks.setup]
description = "Initialize jj workspace tracking AUR"
run = "{{env.PACKAGING_ROOT}}/.mise/tasks/setup-workspace"

[tasks.sync]
description = "Sync with AUR remote"
depends = ["setup"]
run = "{{env.PACKAGING_ROOT}}/.mise/tasks/sync-upstream"

[tasks.build]
description = "Build AUR package"
run = '''
#!/usr/bin/env bash
cd "$WORKSPACE"
makepkg -sf
'''

[tasks.test]
description = "Install and smoke test"
run = '''
#!/usr/bin/env bash
cd "$WORKSPACE"
makepkg -si --noconfirm
$PKG_NAME --version || $PKG_NAME --help || echo "Installed successfully"
'''

[tasks.srcinfo]
description = "Generate .SRCINFO"
run = '''
#!/usr/bin/env bash
cd "$WORKSPACE"
makepkg --printsrcinfo > .SRCINFO
cp .SRCINFO "$PKG_DIR/"
'''

[tasks.checksums]
description = "Update checksums in PKGBUILD"
run = '''
#!/usr/bin/env bash
cd "$WORKSPACE"
updpkgsums
cp PKGBUILD "$PKG_DIR/"
'''

[tasks.export]
description = "Copy workspace files back to package dir"
run = '''
#!/usr/bin/env bash
cp "$WORKSPACE/PKGBUILD" "$PKG_DIR/"
cp "$WORKSPACE/.SRCINFO" "$PKG_DIR/" 2>/dev/null || true
'''

[tasks.push]
description = "Push to AUR"
run = "{{env.PACKAGING_ROOT}}/.mise/tasks/aur-push"

[tasks.gather-context]
description = "Gather all context for OpenCode"
run = "{{env.PACKAGING_ROOT}}/.mise/tasks/gather-context"
```

---

### 4. Shared Task Scripts

All scripts in `.mise/tasks/` are executable bash scripts.

#### .mise/tasks/setup-workspace

```bash
#!/usr/bin/env bash
set -euo pipefail

# Works for both Docker (upstream = app source) and AUR (upstream = AUR remote)

mkdir -p "$(dirname "$WORKSPACE")"

if [[ "$PKG_TYPE" == "docker" ]]; then
    # Docker: clone app upstream
    if [[ -z "$UPSTREAM" ]]; then
        echo "ERROR: No .upstream file found"
        exit 1
    fi
    
    if [[ ! -d "$WORKSPACE/.jj" ]]; then
        echo "Cloning upstream: $UPSTREAM"
        git clone "$UPSTREAM" "$WORKSPACE"
        cd "$WORKSPACE"
        jj git init --colocate
        jj git remote add upstream "$UPSTREAM"
    fi
    
    # Apply existing patches if any
    if [[ -d "$PKG_DIR/patches" ]] && ls "$PKG_DIR/patches"/*.patch 1>/dev/null 2>&1; then
        cd "$WORKSPACE"
        
        # Reset to upstream ref
        REF="${UPSTREAM_REF:-main}"
        jj new "$REF" -m "base"
        
        for patch in "$PKG_DIR/patches"/*.patch; do
            echo "Applying: $(basename "$patch")"
            PATCH_NAME=$(basename "$patch" .patch | sed 's/^[0-9]*-//')
            git apply "$patch"
            jj commit -m "$PATCH_NAME"
        done
    fi

elif [[ "$PKG_TYPE" == "aur" ]]; then
    # AUR: clone AUR remote (or init empty if new package)
    if [[ ! -d "$WORKSPACE/.jj" ]]; then
        if [[ -n "$AUR_REMOTE" ]]; then
            echo "Cloning AUR: $AUR_REMOTE"
            git clone "$AUR_REMOTE" "$WORKSPACE" 2>/dev/null || {
                echo "New package, initializing empty repo"
                mkdir -p "$WORKSPACE"
                cd "$WORKSPACE"
                git init
                git remote add origin "$AUR_REMOTE"
            }
        else
            echo "No AUR remote, initializing local workspace"
            mkdir -p "$WORKSPACE"
            cd "$WORKSPACE"
            git init
        fi
        cd "$WORKSPACE"
        jj git init --colocate
    fi
    
    # Copy our PKGBUILD etc. to workspace
    cp "$PKG_DIR/PKGBUILD" "$WORKSPACE/" 2>/dev/null || true
    cp "$PKG_DIR/.SRCINFO" "$WORKSPACE/" 2>/dev/null || true
fi

echo "Workspace ready: $WORKSPACE"
```

#### .mise/tasks/sync-upstream

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$WORKSPACE"

if [[ "$PKG_TYPE" == "docker" ]]; then
    echo "Fetching upstream..."
    jj git fetch upstream
    
    echo "Rebasing patches onto upstream..."
    jj rebase -d main@upstream 2>&1 || true
    
    # Check for conflicts
    if jj log -r @ --no-graph 2>&1 | grep -q "conflict"; then
        echo "STATUS: CONFLICTS"
        jj status
        exit 1
    else
        echo "STATUS: CLEAN"
    fi

elif [[ "$PKG_TYPE" == "aur" ]]; then
    echo "Fetching from AUR..."
    jj git fetch origin 2>/dev/null || echo "No remote or new package"
    
    # Sync our files
    cp "$PKG_DIR/PKGBUILD" "$WORKSPACE/"
    cp "$PKG_DIR/.SRCINFO" "$WORKSPACE/" 2>/dev/null || true
    
    echo "STATUS: SYNCED"
fi
```

#### .mise/tasks/export-patches

```bash
#!/usr/bin/env bash
set -euo pipefail

# Only meaningful for Docker packages (patches on upstream source)
if [[ "$PKG_TYPE" != "docker" ]]; then
    echo "export-patches: skipping for $PKG_TYPE packages"
    exit 0
fi

cd "$WORKSPACE"

# Determine base commit (upstream)
BASE=$(jj log -r "main@upstream" --no-graph -T 'commit_id' 2>/dev/null || echo "")
if [[ -z "$BASE" ]]; then
    echo "Cannot determine upstream base"
    exit 1
fi

echo "Exporting patches from upstream to HEAD..."

rm -rf "$PKG_DIR/patches"
mkdir -p "$PKG_DIR/patches"

# Get list of commits between upstream and HEAD (oldest first)
COMMITS=$(jj log -r "($BASE)..@" --no-graph -T 'commit_id.short() ++ "\n"' 2>/dev/null | tac)

COUNT=1
for rev in $COMMITS; do
    [[ -z "$rev" ]] && continue
    
    PADDED=$(printf "%04d" $COUNT)
    
    # Get commit message for filename
    MSG=$(jj log -r "$rev" --no-graph -T 'description.first_line()' 2>/dev/null || echo "patch")
    SAFE_MSG=$(echo "$MSG" | tr ' ' '-' | tr -cd 'a-zA-Z0-9-' | head -c 50)
    
    FILENAME="${PADDED}-${SAFE_MSG}.patch"
    
    echo "Exporting: $FILENAME"
    jj diff -r "$rev" --git > "$PKG_DIR/patches/$FILENAME"
    
    ((COUNT++))
done

# Update upstream ref
jj log -r "main@upstream" --no-graph -T 'commit_id' > "$PKG_DIR/.upstream-ref"

echo "Exported $((COUNT-1)) patches"
echo "Updated .upstream-ref to $(cat "$PKG_DIR/.upstream-ref" | head -c 12)..."
```

#### .mise/tasks/gather-context

```bash
#!/usr/bin/env bash
set -euo pipefail

# Gather all context for OpenCode before invocation
# This runs AFTER setup and sync attempts - reads their outputs

cat << HEADER
================================================================================
PACKAGE CONTEXT: $PKG_NAME ($PKG_TYPE)
================================================================================

=== PACKAGE INFO ===
Name: $PKG_NAME
Type: $PKG_TYPE
Directory: $PKG_DIR
Workspace: $WORKSPACE
HEADER

if [[ "$PKG_TYPE" == "docker" ]]; then
    cat << DOCKER_INFO
Upstream: ${UPSTREAM:-none}
Current Ref: ${UPSTREAM_REF:-none}
Registries: ${REGISTRIES:-none}
DOCKER_INFO
elif [[ "$PKG_TYPE" == "aur" ]]; then
    cat << AUR_INFO
AUR Remote: ${AUR_REMOTE:-none}
AUR_INFO
fi

echo ""
echo "=== SYNC OUTPUT ==="
if [[ -f /tmp/sync-output.txt ]]; then
    cat /tmp/sync-output.txt
else
    echo "(no sync output captured)"
fi

echo ""
echo "=== BUILD OUTPUT ==="
if [[ -f /tmp/build-output.txt ]]; then
    cat /tmp/build-output.txt
else
    echo "(no build output captured)"
fi

echo ""
echo "=== CURRENT PATCHES ==="
if [[ -d "$PKG_DIR/patches" ]]; then
    ls -1 "$PKG_DIR/patches/" 2>/dev/null || echo "(no patches)"
else
    echo "(no patches directory)"
fi

echo ""
echo "=== CHANGELOG (new upstream commits) ==="
if [[ -f /tmp/changelog.txt ]]; then
    cat /tmp/changelog.txt
else
    echo "(no changelog captured)"
fi

echo ""
echo "=== AGENTS.MD ==="
if [[ -f "$PKG_DIR/AGENTS.md" ]]; then
    cat "$PKG_DIR/AGENTS.md"
else
    echo "(no AGENTS.md found)"
fi

echo ""
echo "================================================================================"
```

#### .mise/tasks/aur-push

```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ -z "$AUR_REMOTE" ]]; then
    echo "ERROR: No .aur-remote configured"
    exit 1
fi

cd "$WORKSPACE"

# Ensure we have the latest from our package dir
cp "$PKG_DIR/PKGBUILD" "$WORKSPACE/"
cp "$PKG_DIR/.SRCINFO" "$WORKSPACE/"

# Stage and commit
jj new -m "Update package"
git add PKGBUILD .SRCINFO

# Get commit message from parent repo's latest commit or use default
COMMIT_MSG="${COMMIT_MSG:-Update $(date +%Y-%m-%d)}"

jj commit -m "$COMMIT_MSG"

# Push to AUR
echo "Pushing to AUR: $AUR_REMOTE"
jj git push --remote origin

echo "Successfully pushed to AUR"
```

---

### 5. CI Workflows

#### .github/workflows/check-updates.yml

```yaml
name: Package Updates

on:
  schedule:
    - cron: "0 5 * * *"
  workflow_dispatch:
    inputs:
      package:
        description: 'Specific package to update (e.g., docker/clawd.bot, aur/promptfoo)'
        required: false

permissions:
  contents: write
  pull-requests: write
  issues: write
  packages: read

env:
  LLM_PROXY_URL: ${{ vars.LLM_PROXY_URL }}
  LLM_MODEL: ${{ vars.LLM_MODEL }}

jobs:
  detect-updates:
    runs-on: ubuntu-latest
    outputs:
      packages: ${{ steps.detect.outputs.packages }}
      has_updates: ${{ steps.detect.outputs.has_updates }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install nvchecker
        run: pip install nvchecker
      
      - name: Run nvchecker
        run: nvchecker -c nvchecker.toml
      
      - name: Detect updates
        id: detect
        run: |
          python3 << 'PYEOF'
          import json
          import os
          
          old_path = '.github/nvchecker/old_ver.json'
          new_path = '.github/nvchecker/new_ver.json'
          
          # Load version data
          old_data = {}
          if os.path.exists(old_path):
              with open(old_path) as f:
                  old_raw = json.load(f)
                  old_data = old_raw.get('data', old_raw)  # Handle both formats
          
          with open(new_path) as f:
              new_raw = json.load(f)
              new_data = new_raw.get('data', new_raw)
          
          updates = []
          for pkg, new_info in new_data.items():
              # Handle both {"version": "x"} and plain "x" formats
              new_ver = new_info['version'] if isinstance(new_info, dict) else new_info
              
              old_info = old_data.get(pkg, {})
              old_ver = old_info.get('version') if isinstance(old_info, dict) else old_info
              
              if old_ver != new_ver:
                  updates.append({
                      "package": pkg,
                      "old_version": old_ver or "unknown",
                      "new_version": new_ver,
                  })
          
          # Handle manual single-package trigger
          manual_pkg = os.environ.get('MANUAL_PACKAGE', '')
          if manual_pkg:
              updates = [u for u in updates if u['package'] == manual_pkg]
              if not updates and manual_pkg in new_data:
                  # Force update even if version unchanged
                  new_info = new_data[manual_pkg]
                  new_ver = new_info['version'] if isinstance(new_info, dict) else new_info
                  updates = [{
                      "package": manual_pkg,
                      "old_version": "forced",
                      "new_version": new_ver,
                  }]
          
          with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
              f.write(f"packages={json.dumps(updates)}\n")
              f.write(f"has_updates={'true' if updates else 'false'}\n")
          
          print(f"Found {len(updates)} updates: {[u['package'] for u in updates]}")
          PYEOF
        env:
          MANUAL_PACKAGE: ${{ inputs.package }}
      
      - name: Upload nvchecker state
        uses: actions/upload-artifact@v4
        with:
          name: nvchecker-state
          path: .github/nvchecker/new_ver.json

  update-package:
    needs: detect-updates
    if: needs.detect-updates.outputs.has_updates == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 30
    container:
      image: ghcr.io/${{ github.repository }}/builder:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    strategy:
      matrix:
        update: ${{ fromJson(needs.detect-updates.outputs.packages) }}
      fail-fast: false
      max-parallel: 1
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup git
        run: |
          git config --global --add safe.directory "$GITHUB_WORKSPACE"
          git config --global user.name "github-actions[bot]"
          git config --global user.email "github-actions[bot]@users.noreply.github.com"
      
      - name: Restore workspace cache
        uses: actions/cache@v4
        with:
          path: .cache/
          key: workspace-${{ matrix.update.package }}-${{ github.sha }}
          restore-keys: |
            workspace-${{ matrix.update.package }}-
      
      - name: Setup workspace
        run: mise -C ${{ matrix.update.package }} setup
      
      - name: Fetch changelog
        id: changelog
        run: |
          PKG_TYPE=$(echo "${{ matrix.update.package }}" | cut -d/ -f1)
          PKG_DIR="${{ matrix.update.package }}"
          
          if [[ "$PKG_TYPE" == "docker" ]]; then
            WORKSPACE=".cache/${{ matrix.update.package }}"
            OLD_REF=$(cat "$PKG_DIR/.upstream-ref" 2>/dev/null || echo "")
            
            if [[ -n "$OLD_REF" ]] && [[ -d "$WORKSPACE" ]]; then
              cd "$WORKSPACE"
              jj git fetch upstream 2>/dev/null || true
              jj log -r "($OLD_REF)..main@upstream" --no-graph \
                -T 'commit_id.short() ++ " " ++ description.first_line() ++ "\n"' \
                > /tmp/changelog.txt 2>/dev/null || echo "Unable to fetch changelog" > /tmp/changelog.txt
              cd -
            else
              echo "No previous ref or workspace" > /tmp/changelog.txt
            fi
          else
            echo "AUR package - check upstream release notes" > /tmp/changelog.txt
          fi
      
      - name: Try sync
        id: sync
        continue-on-error: true
        run: |
          mise -C ${{ matrix.update.package }} sync 2>&1 | tee /tmp/sync-output.txt
          echo "exit_code=${PIPESTATUS[0]}" >> $GITHUB_OUTPUT
      
      - name: Try build (if sync succeeded)
        id: build
        if: steps.sync.outputs.exit_code == '0'
        continue-on-error: true
        run: |
          mise -C ${{ matrix.update.package }} build 2>&1 | tee /tmp/build-output.txt
          echo "exit_code=${PIPESTATUS[0]}" >> $GITHUB_OUTPUT
      
      - name: Gather all context
        run: mise -C ${{ matrix.update.package }} gather-context > /tmp/full-context.txt
      
      - name: Setup OpenCode config
        env:
          LLM_API_KEY: ${{ secrets.LLM_PROXY_API_KEY }}
        run: |
          mkdir -p .opencode
          cat > .opencode/opencode.json << EOF
          {
            "\$schema": "https://opencode.ai/config.json",
            "permission": {"bash": "allow", "edit": "allow", "write": "allow"},
            "provider": {
              "llmproxy": {
                "npm": "@ai-sdk/openai-compatible",
                "name": "LLM Proxy",
                "options": {
                  "baseURL": "$LLM_PROXY_URL",
                  "apiKey": "$LLM_API_KEY"
                },
                "models": {
                  "$LLM_MODEL": {"name": "LLM Model", "limit": {"context": 200000, "output": 64000}}
                }
              }
            }
          }
          EOF
      
      - name: Invoke OpenCode
        env:
          LLM_PROXY_API_KEY: ${{ secrets.LLM_PROXY_API_KEY }}
          GH_TOKEN: ${{ github.token }}
          AUR_SSH_PRIVATE_KEY: ${{ secrets.AUR_SSH_PRIVATE_KEY }}
        run: |
          cat > /tmp/prompt.md << 'PROMPT_EOF'
          # Update: ${{ matrix.update.package }}
          ## Version: ${{ matrix.update.old_version }} → ${{ matrix.update.new_version }}
          
          $(cat /tmp/full-context.txt)
          
          ---
          
          ## Goal
          
          Make this package build successfully with the new upstream version, 
          then commit your changes and create a PR.
          
          ## Available mise tasks
          
          - `mise -C ${{ matrix.update.package }} setup` - Initialize workspace
          - `mise -C ${{ matrix.update.package }} sync` - Fetch and rebase
          - `mise -C ${{ matrix.update.package }} build` - Build package
          - `mise -C ${{ matrix.update.package }} test` - Test package
          - `mise -C ${{ matrix.update.package }} export` - Export patches/files back
          - `mise -C ${{ matrix.update.package }} checksums` - Update checksums (AUR)
          - `mise -C ${{ matrix.update.package }} srcinfo` - Generate .SRCINFO (AUR)
          
          ## Workspace location
          
          .cache/${{ matrix.update.package }}
          
          PROMPT_EOF
          
          opencode run "$(cat /tmp/prompt.md)"

  update-nvchecker-state:
    needs: [detect-updates, update-package]
    if: always() && needs.detect-updates.result == 'success'
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Download nvchecker state
        uses: actions/download-artifact@v4
        with:
          name: nvchecker-state
          path: .github/nvchecker/
        continue-on-error: true
      
      - name: Update state file
        run: |
          if [[ -f .github/nvchecker/new_ver.json ]]; then
            cp .github/nvchecker/new_ver.json .github/nvchecker/old_ver.json
            
            git config user.name "github-actions[bot]"
            git config user.email "github-actions[bot]@users.noreply.github.com"
            git add .github/nvchecker/old_ver.json
            
            if ! git diff --staged --quiet; then
              git commit -m "chore: update nvchecker version state"
              git push
            fi
          fi
```

#### .github/workflows/docker-push.yml

```yaml
name: Docker Push

on:
  push:
    branches: [main]
    paths:
      - 'docker/**/patches/**'
      - 'docker/**/.upstream-ref'
      - 'docker/**/.registries'

permissions:
  contents: read
  packages: write

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      packages: ${{ steps.detect.outputs.packages }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2
      
      - name: Detect changed docker packages
        id: detect
        run: |
          PACKAGES=$(git diff --name-only HEAD~1 HEAD | \
            grep '^docker/' | \
            cut -d/ -f1-2 | \
            sort -u | \
            jq -R -s -c 'split("\n") | map(select(length > 0))')
          echo "packages=$PACKAGES" >> $GITHUB_OUTPUT
          echo "Changed packages: $PACKAGES"

  push-images:
    needs: detect-changes
    if: needs.detect-changes.outputs.packages != '[]'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        package: ${{ fromJson(needs.detect-changes.outputs.packages) }}
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: jdx/mise-action@v2
      
      - name: Restore workspace cache
        uses: actions/cache@v4
        with:
          path: .cache/
          key: workspace-${{ matrix.package }}-${{ github.sha }}
          restore-keys: |
            workspace-${{ matrix.package }}-
      
      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      # Add more registry logins as needed
      # - name: Login to Docker Hub
      #   uses: docker/login-action@v3
      #   with:
      #     username: ${{ secrets.DOCKERHUB_USERNAME }}
      #     password: ${{ secrets.DOCKERHUB_TOKEN }}
      
      - name: Setup, sync, and build
        run: |
          mise -C ${{ matrix.package }} setup
          mise -C ${{ matrix.package }} sync
          mise -C ${{ matrix.package }} build
      
      - name: Push to registries
        run: mise -C ${{ matrix.package }} push
```

#### .github/workflows/aur-push.yml

```yaml
name: Push to AUR

on:
  push:
    branches: [main]
    paths:
      - 'aur/**/PKGBUILD'
      - 'aur/**/.SRCINFO'

jobs:
  push-to-aur:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2

      - name: Setup SSH for AUR
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.AUR_SSH_PRIVATE_KEY }}" > ~/.ssh/aur
          chmod 600 ~/.ssh/aur
          ssh-keyscan aur.archlinux.org >> ~/.ssh/known_hosts
          
          cat >> ~/.ssh/config << 'EOF'
          Host aur.archlinux.org
            IdentityFile ~/.ssh/aur
            User aur
            IdentitiesOnly yes
          EOF

      - name: Determine changed packages
        id: changed
        run: |
          packages=$(git diff --name-only HEAD~1 HEAD \
            | grep '^aur/' \
            | cut -d/ -f2 \
            | sort -u \
            | tr '\n' ' ')
          echo "packages=$packages" >> $GITHUB_OUTPUT
          echo "Changed packages: $packages"

      - name: Push to AUR
        run: |
          for pkg in ${{ steps.changed.outputs.packages }}; do
            echo "═══════════════════════════════════════════════"
            echo "Pushing $pkg to AUR..."
            echo "═══════════════════════════════════════════════"
            
            cd aur/$pkg
            
            # Clone or init AUR repo
            git clone ssh://aur@aur.archlinux.org/$pkg.git ../aur-$pkg-temp 2>/dev/null || {
              echo "New package, initializing..."
              mkdir -p ../aur-$pkg-temp
              cd ../aur-$pkg-temp
              git init --initial-branch=master
              git remote add origin ssh://aur@aur.archlinux.org/$pkg.git
              cd -
            }
            
            # Copy only PKGBUILD and .SRCINFO (NOT AGENTS.md etc)
            cp PKGBUILD .SRCINFO ../aur-$pkg-temp/
            cd ../aur-$pkg-temp
            
            git config user.name "github-actions[bot]"
            git config user.email "github-actions[bot]@users.noreply.github.com"
            
            git add PKGBUILD .SRCINFO
            
            # Use commit message from main repo
            COMMIT_MSG=$(git -C "$GITHUB_WORKSPACE" log --format=%s -1)
            
            if ! git diff --staged --quiet; then
              git commit -m "$COMMIT_MSG"
              git push origin master
              echo "✅ Successfully pushed $pkg to AUR"
            else
              echo "⏭️ No changes to push for $pkg"
            fi
            
            cd "$GITHUB_WORKSPACE"
          done

      - name: Summary
        run: |
          echo "## AUR Push Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          for pkg in ${{ steps.changed.outputs.packages }}; do
            echo "- [$pkg](https://aur.archlinux.org/packages/$pkg)" >> $GITHUB_STEP_SUMMARY
          done
```

---

### 6. Builder Container

The builder container should have all tools pre-installed for speed.

#### docker/aur-builder/Dockerfile

```dockerfile
FROM archlinux:base-devel

# Update and install base packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        git \
        openssh \
        github-cli \
        docker \
        jq \
        npm \
        python \
        python-pip \
        sudo \
        fakeroot \
        binutils

# Install mise
RUN curl https://mise.run | sh && \
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> /etc/bash.bashrc

# Install jj via mise (or cargo)
RUN ~/.local/bin/mise use -g jj@latest

# Install opencode
RUN npm install -g opencode-ai

# Create builder user
RUN useradd -m builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Setup for makepkg
USER builder
WORKDIR /workspace

# Ensure mise is available
ENV PATH="/home/builder/.local/bin:${PATH}"

COPY --chown=builder:builder entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
```

#### docker/aur-builder/entrypoint.sh

```bash
#!/bin/bash
set -e

# Setup SSH for AUR if key provided
if [ -n "$AUR_SSH_PRIVATE_KEY" ]; then
    mkdir -p ~/.ssh
    echo "$AUR_SSH_PRIVATE_KEY" > ~/.ssh/aur_key
    chmod 600 ~/.ssh/aur_key
    ssh-keyscan aur.archlinux.org >> ~/.ssh/known_hosts 2>/dev/null
    
    cat >> ~/.ssh/config << 'EOF'
Host aur.archlinux.org
  IdentityFile ~/.ssh/aur_key
  User aur
  IdentitiesOnly yes
EOF
fi

# Git config
if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# Fix permissions if needed
if [ -d /workspace ] && [ "$(stat -c '%U' /workspace)" != "builder" ]; then
    sudo chown -R builder:builder /workspace 2>/dev/null || true
fi

# Activate mise
eval "$(mise activate bash)"

exec "$@"
```

---

## Migration Guide

### Migrating Existing clawdbot Fork

1. **Extract patches from existing fork:**
   ```bash
   git clone https://github.com/theblazehen/clawdbot /tmp/clawdbot-fork
   cd /tmp/clawdbot-fork
   git remote add upstream https://github.com/clawdbot/clawdbot
   git fetch upstream
   
   # Find the divergence point
   UPSTREAM_REF=$(git merge-base HEAD upstream/main)
   echo $UPSTREAM_REF
   
   # Export patches
   mkdir -p patches
   git format-patch $UPSTREAM_REF --stdout > patches/all.patch
   # Or per-commit:
   git format-patch $UPSTREAM_REF -o patches/
   ```

2. **Create package structure:**
   ```bash
   mkdir -p docker/clawd.bot/patches
   echo "https://github.com/clawdbot/clawdbot" > docker/clawd.bot/.upstream
   echo "$UPSTREAM_REF" > docker/clawd.bot/.upstream-ref
   echo "ghcr.io/theblazehen/clawd.bot" > docker/clawd.bot/.registries
   cp /tmp/clawdbot-fork/patches/*.patch docker/clawd.bot/patches/
   ```

3. **Create mise.toml** (from template above)

4. **Create AGENTS.md:**
   ```markdown
   # Package: clawd.bot
   
   ## Upstream
   - Repository: https://github.com/clawdbot/clawdbot
   - Type: Docker image with patches
   
   ## Our Changes
   - Dockerfile for containerization
   - Entry point modifications for Docker
   - GitHub workflow for automated builds
   
   ## Build
   ```bash
   mise setup
   mise sync
   mise build
   mise test
   ```
   
   ## Update Workflow
   When upstream updates:
   1. `mise sync` rebases our patches
   2. Resolve any conflicts in `.cache/docker/clawd.bot/`
   3. `mise build` to test
   4. `mise export` to save updated patches
   ```

5. **Test:**
   ```bash
   mise -C docker/clawd.bot setup
   mise -C docker/clawd.bot sync
   mise -C docker/clawd.bot build
   ```

6. **Add to nvchecker.toml:**
   ```toml
   [docker/clawd.bot]
   source = "git"
   git = "https://github.com/clawdbot/clawdbot.git"
   use_commit = true
   ```

### Migrating Existing AUR Packages

Existing AUR packages mostly stay the same, just add:

1. **Create .aur-remote file:**
   ```bash
   echo "ssh://aur@aur.archlinux.org/promptfoo.git" > aur/promptfoo/.aur-remote
   ```

2. **Create mise.toml** (from AUR template above)

3. **Update nvchecker.toml** with namespaced key:
   ```toml
   # Change from:
   [promptfoo]
   # To:
   [aur/promptfoo]
   ```

4. **Update old_ver.json** keys to match

---

## Summary

| Component | Purpose |
|-----------|---------|
| **nvchecker.toml** | Single source of truth for all version tracking (namespaced) |
| **mise.toml (root)** | Monorepo config, shared settings, convenience tasks |
| **mise.toml (per-package)** | Package-specific tasks, env vars, tool deps |
| **.mise/tasks/** | Shared scripts for workspace management |
| **.cache/** | gitignored jj workspaces |
| **patches/** | Per-package patch files (committed, source of truth) |
| **AGENTS.md** | Per-package instructions for OpenCode |
| **check-updates.yml** | nvchecker → pre-run setup/sync/build → gather context → OpenCode → PR/Issue |
| **docker-push.yml** | On merge, build and push to configured registries |
| **aur-push.yml** | On merge, push PKGBUILD + .SRCINFO to AUR |
| **builder container** | Pre-installed mise, jj, opencode, makepkg tools |

### Key Decisions

1. **jj for everything with upstream** - Unified workflow for Docker and AUR
2. **Patches as source of truth** - Committed files, not jj state
3. **Pre-gather context** - Run setup/sync/build before OpenCode, feed all output at once
4. **mise for orchestration** - Task deps, tool management, monorepo support
5. **30 minute timeout** - Give OpenCode time to work
6. **No upstream source in repo** - Minimal bloat, fetch on demand
7. **Cached workspaces** - Speed up CI runs
