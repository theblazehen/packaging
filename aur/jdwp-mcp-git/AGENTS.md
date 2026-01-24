# Package: jdwp-mcp-git

## Upstream
- Repository: https://github.com/navicore/jdwp-mcp
- Language: Rust (cargo workspace)
- Version tracking: git commits (no releases yet)

## Update Detection
```bash
git ls-remote https://github.com/navicore/jdwp-mcp.git HEAD
```

## Update Instructions
1. Run `makepkg -o` to fetch latest source and update pkgver
2. Test build with `makepkg -sf`
3. Test install with `makepkg -si`
4. Verify binary works: `jdwp-mcp --help` or check it starts
5. Regenerate `.SRCINFO`
6. Commit with message: "jdwp-mcp-git: update to r<count>.<hash>"

## Build Notes
- Rust workspace with two crates: `mcp-server` and `jdwp-client`
- Main binary is `jdwp-mcp` from mcp-server crate
- Uses `cargo fetch --locked` for reproducibility
- Runtime: connects to JVMs via JDWP (Java Debug Wire Protocol)

## Usage
Configure in Claude Code's `.mcp.json`:
```json
{
  "mcpServers": {
    "jdwp": {
      "command": "/usr/bin/jdwp-mcp"
    }
  }
}
```
