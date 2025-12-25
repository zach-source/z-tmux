# z-tmux

Reproducible tmux setup with Nix, featuring:

- **Catppuccin** theme (latte/frappe/macchiato/mocha)
- **tmux-which-key** for discoverability (`prefix + Space`)
- **tmux-resurrect + continuum** for session persistence
- **tmuxp** for declarative session management
- **Workspace launcher** with zoxide integration
- **Plugin suite**: copycat, open, sessionist, cowboy, logging

## Quick Start

### Try It Out

```bash
nix run github:zach-source/z-tmux
```

Or clone and run locally:

```bash
git clone https://github.com/zach-source/z-tmux
cd z-tmux
nix run .#test
```

### As a Home Manager Module

Add to your flake inputs:

```nix
{
  inputs = {
    z-tmux.url = "github:zach-source/z-tmux";
  };
}
```

Import and enable in your home configuration:

```nix
{ inputs, ... }:
{
  imports = [ inputs.z-tmux.homeManagerModules.default ];

  z-tmux = {
    enable = true;
    catppuccinFlavor = "mocha";  # or: latte, frappe, macchiato
    # prefix = "C-a";            # default: C-b
    # saveInterval = 10;         # default: 15 minutes
  };
}
```

## Module Options

### Core Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `z-tmux.enable` | bool | `false` | Enable z-tmux configuration |
| `z-tmux.package` | package | `pkgs.tmux` | The tmux package to use |
| `z-tmux.prefix` | string | `"C-b"` | Tmux prefix key |
| `z-tmux.catppuccinFlavor` | enum | `"mocha"` | Theme: latte/frappe/macchiato/mocha |
| `z-tmux.saveInterval` | int | `15` | Continuum save interval (minutes) |
| `z-tmux.enableMosh` | bool | `true` | Install mosh for remote connections |
| `z-tmux.enableTmuxp` | bool | `true` | Install tmuxp for session management |
| `z-tmux.extraConfig` | lines | `""` | Extra tmux configuration lines |
| `z-tmux.workspacesDir` | string | `"$HOME/repos/workspaces"` | Directory for workspace launcher |

### Plugin Options

All plugins are enabled by default. Disable individually as needed:

| Option | Default | Description |
|--------|---------|-------------|
| `z-tmux.plugins.sensible` | `true` | Sensible defaults |
| `z-tmux.plugins.yank` | `true` | Clipboard integration |
| `z-tmux.plugins.resurrect` | `true` | Session persistence (save/restore) |
| `z-tmux.plugins.continuum` | `true` | Auto-save sessions |
| `z-tmux.plugins.open` | `true` | Open URLs/files from copy mode |
| `z-tmux.plugins.sessionist` | `true` | Session management utilities |
| `z-tmux.plugins.copycat` | `true` | Regex search in scrollback |
| `z-tmux.plugins.cowboy` | `true` | Kill unresponsive processes |
| `z-tmux.plugins.logging` | `true` | Pane logging and capture |
| `z-tmux.plugins.whichKey` | `true` | Discoverable key bindings menu |
| `z-tmux.plugins.prefixHighlight` | `true` | Show prefix state in status |

Example minimal config (disable optional plugins):

```nix
z-tmux = {
  enable = true;
  plugins = {
    cowboy = false;
    logging = false;
    copycat = false;
  };
};
```

## Which-Key Menu

Press `prefix + Space` to open the which-key menu. Menus are organized by category:

| Key | Menu | Description |
|-----|------|-------------|
| `W` | Workspace | Launch workspace picker (zoxide-sorted) |
| `\` | Split window | New window with two vertical panes |
| `C` | Claude dev | nvim + claude-smart/claude in split panes |
| `y` | +Copy | Copy mode, buffers, paste |
| `/` | +Search | Copycat regex search, URLs, files, IPs |
| `w` | +Windows | Window management, layouts, splits |
| `p` | +Panes | Pane navigation, resize, zoom |
| `s` | +Sessions | Session management, tmuxp, sessionist |
| `S` | +System | Reload config, logging, client management |
| `?` | Keys | List all key bindings |
| `R` | Reload | Reload tmux configuration |

### Submenus

**+Search** (copycat integration):
- `/` Regex search
- `f` Find files
- `u` Find URLs
- `g` Git files (status output)
- `d` Digits
- `h` Hashes (git, etc)
- `i` IP addresses

**+Panes**:
- `hjkl` Navigate panes
- `r` Resize submenu (transient, repeatable)
- `z` Zoom toggle
- `*` Kill process (cowboy)
- `R` Respawn pane

**+Sessions**:
- `t` Load tmuxp session
- `S` Save current as tmuxp
- `g` Sessionist submenu (switch, create, promote pane)

## Direct Key Bindings

| Binding | Action |
|---------|--------|
| `prefix + Space` | Open which-key menu |
| `prefix + \|` | Split horizontal |
| `prefix + -` | Split vertical |
| `prefix + c` | New window |
| `prefix + h/j/k/l` | Navigate panes |
| `prefix + H/J/K/L` | Resize panes |
| `prefix + p` | Popup terminal |
| `prefix + s` | Session chooser |
| `prefix + r` | Reload config |
| `prefix + Enter` | Enter copy mode |
| `prefix + S` | Save layout as tmuxp |
| `prefix + C-s` | Save session (resurrect) |
| `prefix + C-r` | Restore session (resurrect) |

## Workspace Launcher

Press `prefix + Space`, then `W` to open the workspace launcher.

Features:
- Scans `~/repos/workspaces` for git repositories
- Sorted by zoxide frecency score
- Opens with Claude dev layout (nvim + claude)
- Automatically adds to zoxide history

## Development Shortcuts

### Split Window (`prefix + Space`, `\`)
Creates a new window with two vertical panes, both starting in the current directory.

### Claude Dev (`prefix + Space`, `C`)
Opens a development window with:
- **Left pane**: `nvim .` - Opens neovim in the current directory
- **Right pane**: `claude-smart` (or `claude` if claude-smart isn't available)

Ideal for AI-assisted coding workflows.

## Plugins Included

| Plugin | Purpose |
|--------|---------|
| tmux-sensible | Sensible defaults |
| tmux-yank | System clipboard integration |
| tmux-resurrect | Session save/restore |
| tmux-continuum | Automatic session saving |
| tmux-which-key | Discoverable key bindings |
| tmux-open | Open URLs/files from copy mode |
| tmux-copycat | Regex search in scrollback |
| tmux-sessionist | Session management utilities |
| tmux-cowboy | Kill unresponsive processes |
| tmux-logging | Pane logging and capture |
| tmux-prefix-highlight | Show prefix state in status |

## tmuxp Sessions

Load a saved session:
```bash
tmuxp load session-name
```

Or via which-key: `prefix + Space`, `s`, `t`

Save current session: `prefix + Space`, `s`, `S`

Sessions are stored in `~/.config/tmuxp/`.

## Architecture

```
z-tmux (Nix Flake)
├── modules/tmux.nix     # Home-manager module
├── tmux/
│   ├── which-key-config.yaml   # Menu configuration
│   └── sessions/               # Example tmuxp sessions
└── flake.nix            # Flake with module + test package

Plugins (bundled via Nix):
├── tpm                  # Plugin manager (for reference)
├── tmux-sensible        # Defaults
├── tmux-yank            # Clipboard
├── tmux-resurrect       # Session persistence
├── tmux-continuum       # Auto-save
├── tmux-which-key       # Menu system
├── tmux-open            # Open URLs/files
├── tmux-copycat         # Regex search
├── tmux-sessionist      # Session utils
├── tmux-cowboy          # Process killer
├── tmux-logging         # Pane logging
└── tmux-prefix-highlight
```

## Development

```bash
# Enter dev shell
nix develop

# Build and run test package
nix build .#test
./result/bin/z-tmux-test

# Evaluate home-manager config
nix eval .#homeConfigurations.aarch64-darwin.z-tmux
```

## License

MIT
