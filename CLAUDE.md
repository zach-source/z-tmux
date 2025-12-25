# z-tmux Project Instructions

## Overview

z-tmux is a Nix flake providing a reproducible tmux configuration as a home-manager module. It bundles plugins directly via Nix (no TPM runtime dependency) and generates tmux-which-key menus from YAML.

## Key Architecture

### File Structure

```
flake.nix              # Exports homeManagerModules.z-tmux + packages.test
modules/tmux.nix       # Home-manager module (main implementation)
tmux/
  which-key-config.yaml  # Which-key menu definitions
  tmux.conf              # Reference config (not used by Nix)
  sessions/              # Example tmuxp session files
```

### How It Works

1. **Plugin Bundling**: Plugins are fetched via `fetchFromGitHub` and bundled into a single directory using `pkgs.linkFarm`
2. **Which-Key Generation**: `tmux/which-key-config.yaml` is processed by `tmux-which-key/plugin/build.py` to generate `init.tmux`
3. **Config Generation**: `tmux.conf` is generated as a Nix derivation (`pkgs.writeText`) with all paths resolved
4. **XDG Paths**: Which-key uses XDG directories for config/data separation

### Important Patterns

**Python in Nix derivations**: Use explicit interpreter path, not `nativeBuildInputs`:
```nix
pythonWithYaml = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
whichKeyInit = pkgs.runCommand "which-key-init" { } ''
  ${pythonWithYaml}/bin/python3 build.py ...
'';
```

**build.py import fix**: The upstream uses `from pyyaml.lib import yaml`, must be patched:
```bash
sed 's/from pyyaml.lib import yaml/import yaml/' build.py
```

**Catppuccin colors**: Defined as Nix attrsets per flavor, interpolated into tmux.conf:
```nix
colors.mocha = { base = "#1e1e2e"; blue = "#89b4fa"; ... };
```

## Which-Key Configuration

Edit `tmux/which-key-config.yaml` to modify menus. Key structures:

```yaml
items:
  - name: "+MenuName"    # Submenu (prefix with +)
    key: "m"
    menu:
      - name: "Action"
        key: "a"
        command: "tmux-command"
        transient: true   # Stay in menu after action (for resize, etc)

  - name: "Direct Action"
    key: "d"
    macro: macro-name     # Reference a macro

macros:
  - name: macro-name
    commands:
      - "command1"
      - "command2"
```

### YAML Quoting Rules

- Commands with colons: Use single quotes outside `command: 'display "foo: bar"'`
- Percent signs: Escape in tmux format strings `'%%'`
- Special keys: Backslash-escape `~` and similar

## Testing Changes

```bash
# Rebuild and test
nix build .#test && ./result/bin/z-tmux-test

# Test specific tmux command
./result/bin/z-tmux-test list-keys -N | grep Space
```

The test script:
- Sets up XDG paths in `~/.cache/z-tmux-test/`
- Copies which-key config and generated init.tmux
- Symlinks tmux.conf to `~/.tmux.conf` for reload-config to work

## Module Options

When modifying `modules/tmux.nix`, available options are:

| Option | Type | Default |
|--------|------|---------|
| `enable` | bool | false |
| `prefix` | str | "C-b" |
| `catppuccinFlavor` | enum | "mocha" |
| `saveInterval` | int | 15 |
| `enableMosh` | bool | true |
| `enableTmuxp` | bool | true |
| `extraConfig` | lines | "" |

## Common Tasks

### Adding a New Plugin

1. Add `fetchFromGitHub` in both `flake.nix` (test) and `modules/tmux.nix` (module)
2. Add to `pluginsDir` linkFarm
3. Add `run-shell` in tmux.conf generation
4. Add keybindings to which-key-config.yaml if needed

### Modifying Which-Key Menus

1. Edit `tmux/which-key-config.yaml`
2. Rebuild: `nix build .#test`
3. Test: `./result/bin/z-tmux-test`

### Changing Theme Colors

Edit the `catppuccinColors` attrset in `modules/tmux.nix`. Each flavor (latte, frappe, macchiato, mocha) has its own color definitions.

## Gotchas

- **Plugin load order**: tmux-which-key must be loaded LAST (it binds prefix+Space)
- **Resurrect paths**: Uses `~/.tmux/resurrect` for session data
- **Logging paths**: Uses `~/.tmux/logs` for pane logs
- **Workspace launcher**: Hardcoded to scan `~/repos/workspaces`
