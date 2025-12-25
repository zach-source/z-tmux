# z-tmux

Reproducible tmux setup with Nix, featuring:

- **Catppuccin Mocha** powerline top bar
- **tmux-which-key** for discoverability
- **tmux-resurrect + continuum** for session persistence
- **tmuxp** for declarative session management
- **mosh** for network-resilient remote connections

## Quick Start

### Using the Dev Shell

```bash
nix develop
```

### As a Home Manager Module

Add to your flake inputs:

```nix
{
  inputs = {
    z-tmux.url = "github:ztaylor/z-tmux";
  };
}
```

Import and enable in your home configuration:

```nix
{ inputs, ... }:
{
  imports = [ inputs.z-tmux.homeManagerModules.default ];

  z-tmux.enable = true;
}
```

### Standalone (without Nix)

1. Install TPM:
   ```bash
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

2. Copy the config:
   ```bash
   cp tmux/tmux.conf ~/.tmux.conf
   ```

3. Install plugins: `prefix + I`

## Module Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `z-tmux.enable` | bool | false | Enable z-tmux configuration |
| `z-tmux.prefix` | string | "C-a" | Tmux prefix key |
| `z-tmux.shell` | string | zsh | Default shell |
| `z-tmux.catppuccinFlavor` | enum | "mocha" | Catppuccin flavor (latte/frappe/macchiato/mocha) |
| `z-tmux.saveInterval` | int | 15 | Continuum save interval (minutes) |
| `z-tmux.enableMosh` | bool | true | Install mosh |
| `z-tmux.enableTmuxp` | bool | true | Install tmuxp |
| `z-tmux.extraConfig` | lines | "" | Extra tmux configuration |

## Key Bindings

| Binding | Action |
|---------|--------|
| `C-a` | Prefix key |
| `prefix + ?` | Which-key help menu |
| `prefix + \|` | Split horizontal |
| `prefix + -` | Split vertical |
| `prefix + h/j/k/l` | Navigate panes (vim-style) |
| `prefix + H/J/K/L` | Resize panes |
| `prefix + p` | Popup terminal |
| `prefix + s` | Session chooser |
| `prefix + r` | Reload config |
| `prefix + C-s` | Save session (resurrect) |
| `prefix + C-r` | Restore session (resurrect) |
| `Alt + arrows` | Navigate panes (no prefix) |
| `Shift + arrows` | Switch windows (no prefix) |

## tmuxp Sessions

Load a session:

```bash
tmuxp load remote-dev
```

Sessions are stored in `~/.config/tmuxp/`.

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                       z-tmux                             │
├──────────────────────────────────────────────────────────┤
│  tmux         - Multiplexing, panes, windows             │
│  tmuxp        - Declarative session/layout creation      │
│  mosh         - Network-resilient remote transport       │
│  resurrect    - Manual session save/restore              │
│  continuum    - Automatic periodic saves + restore       │
│  TPM          - Plugin management                        │
│  Nix          - Reproducible installation                │
└──────────────────────────────────────────────────────────┘
```

## License

MIT
