{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.z-tmux;

  # ══════════════════════════════════════════════════════════════════════════
  # Plugin Sources
  # ══════════════════════════════════════════════════════════════════════════

  # Core plugins
  tpm = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tpm";
    rev = "v3.1.0";
    sha256 = "sha256-CeI9Wq6tHqV68woE11lIY4cLoNY8XWyXyMHTDmFKJKI=";
  };

  tmuxResurrect = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-resurrect";
    rev = "v4.0.0";
    sha256 = "sha256-44Ok7TbNfssMoBmOAqLLOj7oYRG3AQWrCuLzP8tA8Kg=";
  };

  tmuxContinuum = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-continuum";
    rev = "v3.1.0";
    sha256 = "sha256-e02cshLR9a2+uhrU/oew+FPTKhd4mi0/Q02ToHbbVrE=";
  };

  tmuxSensible = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-sensible";
    rev = "v3.0.0";
    sha256 = "sha256-ney/Y1YtCsWLgthOmoYGZTpPfJz+DravRB31YZgnDuU=";
  };

  tmuxYank = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-yank";
    rev = "v2.3.0";
    sha256 = "sha256-DQQCsBHxOo/BepclkICCtVUAL4pozS/RTJBcVLzICns=";
  };

  tmuxPrefixHighlight = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-prefix-highlight";
    rev = "06cbb4ecd3a0a918ce355c70dc56d79debd455c7";
    sha256 = "sha256-wkMm2Myxau24E0fbXINPuL2dc8E4ZYe5Pa6A0fWhiw4=";
  };

  tmuxWhichKey = pkgs.fetchFromGitHub {
    owner = "alexwforsythe";
    repo = "tmux-which-key";
    rev = "1f419775caf136a60aac8e3a269b51ad10b51eb6";
    sha256 = "sha256-X7FunHrAexDgAlZfN+JOUJvXFZeyVj9yu6WRnxMEA8E=";
  };

  # High value plugins
  tmuxOpen = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-open";
    rev = "763d0a852e6703ce0f5090a508330012a7e6788e";
    sha256 = "sha256-Thii7D21MKodtjn/MzMjOGbJX8BwnS+fQqAtYv8CjPc=";
  };

  tmuxSessionist = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-sessionist";
    rev = "a315c423328d9bdf5cf796435ce7075fa5e1bffb";
    sha256 = "sha256-iC8NvuLujTXw4yZBaenHJ+2uM+HA9aW5b2rQTA8e69s=";
  };

  # Optional plugins
  tmuxCowboy = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-cowboy";
    rev = "75702b6d0a866769dd14f3896e9d19f7e0acd4f2";
    sha256 = "sha256-KJNsdDLqT2Uzc25U4GLSB2O1SA/PThmDj9Aej5XjmJs=";
  };

  tmuxLogging = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-logging";
    rev = "b5c5f7b9bc679ca161a442e932d6186da8d3538f";
    sha256 = "sha256-NTDUXxy0Y0dp7qmcH5qqqENGvhzd3lLrIii5u0lYHJk=";
  };

  tmuxCopycat = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-copycat";
    rev = "d7f7e6c1de0bc0d6915f4beea5be6a8a42045c09";
    sha256 = "sha256-2dMu/kbKLI/+kO05+qmeuJtAvvO7k9SSF+o2MHNllFk=";
  };

  # ══════════════════════════════════════════════════════════════════════════
  # Plugin Bundle (dynamic based on enabled plugins)
  # ══════════════════════════════════════════════════════════════════════════

  pluginsList = [
    {
      name = "tpm";
      path = tpm;
    }
  ]
  ++ lib.optional cfg.plugins.sensible {
    name = "tmux-sensible";
    path = tmuxSensible;
  }
  ++ lib.optional cfg.plugins.yank {
    name = "tmux-yank";
    path = tmuxYank;
  }
  ++ lib.optional cfg.plugins.resurrect {
    name = "tmux-resurrect";
    path = tmuxResurrect;
  }
  ++ lib.optional cfg.plugins.continuum {
    name = "tmux-continuum";
    path = tmuxContinuum;
  }
  ++ lib.optional cfg.plugins.prefixHighlight {
    name = "tmux-prefix-highlight";
    path = tmuxPrefixHighlight;
  }
  ++ lib.optional cfg.plugins.open {
    name = "tmux-open";
    path = tmuxOpen;
  }
  ++ lib.optional cfg.plugins.sessionist {
    name = "tmux-sessionist";
    path = tmuxSessionist;
  }
  ++ lib.optional cfg.plugins.cowboy {
    name = "tmux-cowboy";
    path = tmuxCowboy;
  }
  ++ lib.optional cfg.plugins.logging {
    name = "tmux-logging";
    path = tmuxLogging;
  }
  ++ lib.optional cfg.plugins.copycat {
    name = "tmux-copycat";
    path = tmuxCopycat;
  }
  ++ lib.optional cfg.plugins.whichKey {
    name = "tmux-which-key";
    path = tmuxWhichKey;
  };

  pluginsDir = pkgs.linkFarm "tmux-plugins" pluginsList;

  # ══════════════════════════════════════════════════════════════════════════
  # Helper Scripts
  # ══════════════════════════════════════════════════════════════════════════

  # Workspace launcher with zoxide frecency ordering
  workspaceLauncher = pkgs.writeShellScriptBin "tmux-workspace" ''
    #!/usr/bin/env bash
    # Tmux workspace launcher - select from configured workspaces directory
    # Ordered by zoxide frecency score

    WORKSPACES_DIR="${cfg.workspacesDir}"

    if [ ! -d "$WORKSPACES_DIR" ]; then
      echo "Workspaces directory not found: $WORKSPACES_DIR"
      exit 1
    fi

    # Get all workspace directories (those with .git)
    ALL_WORKSPACES=$(find "$WORKSPACES_DIR" -maxdepth 2 -type d -name ".git" 2>/dev/null | \
      xargs -I{} dirname {} | sort)

    # If zoxide is available, use it to order by frecency
    if command -v zoxide >/dev/null 2>&1; then
      ZOXIDE_LIST=$(zoxide query -l -s 2>/dev/null | grep "$WORKSPACES_DIR" || true)

      ORDERED_WORKSPACES=""

      while IFS= read -r line; do
        WS_PATH=$(echo "$line" | awk '{print $2}')
        if [ -n "$WS_PATH" ] && [ -d "$WS_PATH/.git" ]; then
          SCORE=$(echo "$line" | awk '{printf "%.0f", $1}')
          ORDERED_WORKSPACES="$ORDERED_WORKSPACES$WS_PATH [$SCORE]"$'\n'
        fi
      done <<< "$ZOXIDE_LIST"

      while IFS= read -r ws; do
        if [ -n "$ws" ] && ! echo "$ORDERED_WORKSPACES" | grep -q "^$ws "; then
          ORDERED_WORKSPACES="$ORDERED_WORKSPACES$ws [0]"$'\n'
        fi
      done <<< "$ALL_WORKSPACES"

      DISPLAY_LIST=$(echo "$ORDERED_WORKSPACES" | grep -v '^$')
    else
      DISPLAY_LIST=$(echo "$ALL_WORKSPACES" | sed 's/$/ [?]/')
    fi

    # Let user choose with fzf
    if command -v fzf >/dev/null 2>&1; then
      SELECTION=$(echo "$DISPLAY_LIST" | \
        fzf --height 100% --reverse \
            --prompt " Workspace: " \
            --header "Select a workspace (sorted by usage)" \
            --with-nth 1 \
            --delimiter ' \[')
      WORKSPACE=$(echo "$SELECTION" | sed 's/ \[.*$//')
    else
      echo "Available workspaces:"
      echo "$DISPLAY_LIST" | nl
      read -p "Enter number: " num
      SELECTION=$(echo "$DISPLAY_LIST" | sed -n "''${num}p")
      WORKSPACE=$(echo "$SELECTION" | sed 's/ \[.*$//')
    fi

    if [ -n "$WORKSPACE" ] && [ -d "$WORKSPACE" ]; then
      if command -v zoxide >/dev/null 2>&1; then
        zoxide add "$WORKSPACE"
      fi

      # Get window name from directory
      WINDOW_NAME=$(basename "$WORKSPACE")

      # Get current session (works even from popup)
      CURRENT_SESSION=$(tmux display-message -p '#S')

      # Create new window in current session with claude-dev layout
      tmux new-window -t "$CURRENT_SESSION" -n "$WINDOW_NAME" -c "$WORKSPACE"
      tmux send-keys -t "$CURRENT_SESSION:$WINDOW_NAME" "nvim ." Enter
      tmux split-window -t "$CURRENT_SESSION:$WINDOW_NAME" -h -c "$WORKSPACE"
      if command -v claude-smart >/dev/null 2>&1; then
        tmux send-keys -t "$CURRENT_SESSION:$WINDOW_NAME" "claude-smart" Enter
      elif command -v claude >/dev/null 2>&1; then
        tmux send-keys -t "$CURRENT_SESSION:$WINDOW_NAME" "claude" Enter
      fi
      tmux select-pane -t "$CURRENT_SESSION:$WINDOW_NAME" -L

      # Select the new window (popup will close and user sees new window)
      tmux select-window -t "$CURRENT_SESSION:$WINDOW_NAME"
    fi
  '';

  # tmuxp session loader
  tmuxpLoader = pkgs.writeShellScriptBin "tmuxp-loader" ''
    #!/usr/bin/env bash
    # Load a tmuxp session

    TMUXP_DIR="${cfg.tmuxpDir}"

    if [ ! -d "$TMUXP_DIR" ]; then
      echo "No tmuxp configs found at $TMUXP_DIR"
      exit 1
    fi

    CONFIGS=$(find "$TMUXP_DIR" -name "*.yaml" -o -name "*.yml" 2>/dev/null | sort)

    if [ -z "$CONFIGS" ]; then
      echo "No .yaml/.yml files found in $TMUXP_DIR"
      exit 1
    fi

    if command -v fzf >/dev/null 2>&1; then
      SELECTION=$(echo "$CONFIGS" | xargs -I{} basename {} | \
        fzf --height 100% --reverse \
            --prompt " tmuxp: " \
            --header "Select a session to load")
    else
      echo "Available sessions:"
      echo "$CONFIGS" | xargs -I{} basename {} | nl
      read -p "Enter number: " num
      SELECTION=$(echo "$CONFIGS" | xargs -I{} basename {} | sed -n "''${num}p")
    fi

    if [ -n "$SELECTION" ]; then
      tmuxp load -y "$TMUXP_DIR/$SELECTION"
    fi
  '';

  # tmuxp session saver
  tmuxpExportScript = pkgs.writeShellScriptBin "tmux-save-layout" ''
    #!/usr/bin/env bash
    # Export current tmux session to tmuxp format

    SESSION_NAME=$(tmux display-message -p '#S')
    OUTPUT_DIR="${cfg.tmuxpDir}"
    OUTPUT_FILE="$OUTPUT_DIR/$SESSION_NAME.yaml"

    mkdir -p "$OUTPUT_DIR"

    if command -v tmuxp >/dev/null 2>&1; then
      tmuxp freeze -o "$OUTPUT_FILE" -y
      tmux display-message "Session saved to $OUTPUT_FILE"
    else
      tmux display-message "tmuxp not found!"
    fi
  '';

  # Split window - new window with two vertical panes
  splitWindowScript = pkgs.writeShellScriptBin "tmux-split-window" ''
    #!/usr/bin/env bash
    # Create a new tmux window with two vertical panes

    TMUX_BIN="$(command -v tmux)"
    WINDOW_NAME="''${1:-split}"
    WORK_DIR="$(pwd)"

    "$TMUX_BIN" new-window -n "$WINDOW_NAME" -c "$WORK_DIR" \; \
      split-window -h -c "$WORK_DIR" \; \
      select-pane -L
  '';

  # Claude dev - nvim on left, claude on right
  claudeDevScript = pkgs.writeShellScriptBin "tmux-claude-dev" ''
    #!/usr/bin/env bash
    # Create a new tmux window with nvim on left and claude on right

    TMUX_BIN="$(command -v tmux)"
    WORK_DIR="$(pwd)"

    # Determine which claude command to use
    if command -v claude-smart >/dev/null 2>&1; then
      CLAUDE_CMD="claude-smart"
    elif command -v claude >/dev/null 2>&1; then
      CLAUDE_CMD="claude"
    else
      "$TMUX_BIN" display-message "Error: neither claude-smart nor claude found in PATH"
      exit 1
    fi

    "$TMUX_BIN" new-window -n "claude-dev" -c "$WORK_DIR" \; \
      send-keys "nvim ." Enter \; \
      split-window -h -c "$WORK_DIR" \; \
      send-keys "$CLAUDE_CMD" Enter \; \
      select-pane -L
  '';

  # Claude input monitoring script (singleton via flock)
  claudeMonitorScript = pkgs.writeShellScriptBin "tmux-claude-monitor" ''
    #!/usr/bin/env bash
    # Monitor all panes for Claude waiting for input
    # Sets @claude_waiting on windows where Claude is waiting
    # Uses flock to ensure only one instance runs at a time

    # Singleton check using flock
    LOCK_FILE="''${TMPDIR:-/tmp}/tmux-claude-monitor.lock"
    exec 200>"$LOCK_FILE"
    if ! ${pkgs.flock}/bin/flock -n 200; then
      # Another instance is already running
      exit 0
    fi
    # Write PID for debugging
    echo $$ > "''${LOCK_FILE}.pid"

    check_pane_for_claude_waiting() {
      local pane_id="$1"
      local window_id="$2"

      # Capture the last 5 lines of the pane
      local content=$(tmux capture-pane -t "$pane_id" -p -S -5 2>/dev/null)

      # Check for Claude's waiting prompt patterns
      if echo "$content" | grep -qE '^\s*>\s*$|^>\s|Waiting for|waiting for your|^claude>|Human:.*$'; then
        echo "waiting"
        return 0
      fi

      echo "active"
      return 1
    }

    # Main monitoring loop
    while true; do
      tmux list-panes -a -F '#{pane_id} #{window_id} #{window_name}' 2>/dev/null | while read -r pane_id window_id window_name; do
        pane_cmd=$(tmux display-message -t "$pane_id" -p '#{pane_current_command}' 2>/dev/null)

        if [[ "$window_name" == *"claude"* ]] || [[ "$pane_cmd" == *"claude"* ]] || [[ "$pane_cmd" == "node" ]]; then
          status=$(check_pane_for_claude_waiting "$pane_id" "$window_id")
          current=$(tmux show-window-option -t "$window_id" -v @claude_waiting 2>/dev/null)

          if [[ "$status" == "waiting" ]] && [[ "$current" != "1" ]]; then
            tmux set-window-option -t "$window_id" @claude_waiting 1
          fi
        fi
      done

      sleep 2
    done
  '';

  # Script to clear claude waiting indicator
  claudeClearWaitingScript = pkgs.writeShellScriptBin "tmux-claude-clear-waiting" ''
    #!/usr/bin/env bash
    tmux set-window-option @claude_waiting 0 2>/dev/null
  '';

  # ══════════════════════════════════════════════════════════════════════════
  # Which-Key Init Generator
  # ══════════════════════════════════════════════════════════════════════════

  whichKeyConfig = ../tmux/which-key-config.yaml;

  pythonWithYaml = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);

  whichKeyInit = pkgs.runCommand "which-key-init" { } ''
    mkdir -p $out

    # Copy build.py and patch the import
    sed 's/from pyyaml.lib import yaml/import yaml/' \
      ${pluginsDir}/tmux-which-key/plugin/build.py > build.py

    ${pythonWithYaml}/bin/python3 build.py ${whichKeyConfig} $out/init.tmux
  '';

  # ══════════════════════════════════════════════════════════════════════════
  # Catppuccin Theme Colors
  # ══════════════════════════════════════════════════════════════════════════

  catppuccinColors = {
    mocha = {
      rosewater = "#f5e0dc";
      flamingo = "#f2cdcd";
      pink = "#f5c2e7";
      mauve = "#cba6f7";
      red = "#f38ba8";
      maroon = "#eba0ac";
      peach = "#fab387";
      yellow = "#f9e2af";
      green = "#a6e3a1";
      teal = "#94e2d5";
      sky = "#89dceb";
      sapphire = "#74c7ec";
      blue = "#89b4fa";
      lavender = "#b4befe";
      text = "#cdd6f4";
      subtext1 = "#bac2de";
      subtext0 = "#a6adc8";
      overlay2 = "#9399b2";
      overlay1 = "#7f849c";
      overlay0 = "#6c7086";
      surface2 = "#585b70";
      surface1 = "#45475a";
      surface0 = "#313244";
      base = "#1e1e2e";
      mantle = "#181825";
      crust = "#11111b";
    };
    macchiato = {
      base = "#24273a";
      surface0 = "#363a4f";
      blue = "#8aadf4";
      green = "#a6da95";
      peach = "#f5a97f";
      text = "#cad3f5";
    };
    frappe = {
      base = "#303446";
      surface0 = "#414559";
      blue = "#8caaee";
      green = "#a6d189";
      peach = "#ef9f76";
      text = "#c6d0f5";
    };
    latte = {
      base = "#eff1f5";
      surface0 = "#ccd0da";
      blue = "#1e66f5";
      green = "#40a02b";
      peach = "#fe640b";
      text = "#4c4f69";
    };
  };

  colors = catppuccinColors.${cfg.catppuccinFlavor};

  # ══════════════════════════════════════════════════════════════════════════
  # Tmux Configuration
  # ══════════════════════════════════════════════════════════════════════════

  tmuxConf = pkgs.writeText "tmux.conf" ''
    # ══════════════════════════════════════════════════════════════════════
    # z-tmux Configuration
    # Generated by home-manager z-tmux module
    # ══════════════════════════════════════════════════════════════════════

    # Default shell and command (with reattach-to-user-namespace for macOS clipboard)
    set -g default-shell ${cfg.shell}
    set -g default-command "reattach-to-user-namespace -l ${cfg.shell}"

    # Core settings
    set -g default-terminal "tmux-256color"
    set -ag terminal-overrides ",xterm-256color:RGB"
    set -as terminal-features ",xterm-256color:RGB"
    set -g prefix ${cfg.prefix}
    set -g mode-keys vi
    set -g mouse on
    set -g history-limit 50000
    set -g base-index 1
    setw -g pane-base-index 1
    set -g escape-time 0
    set -g focus-events on
    set -g renumber-windows on
    set -g allow-rename off
    setw -g monitor-activity on
    set -g visual-activity off

    # ══════════════════════════════════════════════════════════════════════
    # Status Bar - Catppuccin ${cfg.catppuccinFlavor}
    # ══════════════════════════════════════════════════════════════════════

    set -g status on
    set -g status-position top
    set -g status-interval 5
    set -g status-style "bg=default"

    # Mode indicator in left status
    set -g @mode_indicator_prefix_mode_style "fg=${colors.base},bg=${colors.peach},bold"
    set -g @mode_indicator_copy_mode_style "fg=${colors.base},bg=${colors.yellow},bold"
    set -g @mode_indicator_sync_mode_style "fg=${colors.base},bg=${colors.red},bold"
    set -g @mode_indicator_empty_mode_style "fg=${colors.base},bg=${colors.green},bold"

    # Status left: session name with powerline
    set -g status-left-length 50
    set -g status-left "#[fg=${colors.base},bg=${colors.green},bold]  #S #[fg=${colors.green},bg=default]"

    # Status right: directory
    set -g status-right-length 100
    set -g status-right "#[fg=${colors.blue}]#[fg=${colors.base},bg=${colors.blue},bold] 󰉋 #{=30:pane_current_path} "

    # Window status (with optional Claude waiting indicator)
    set -g window-status-format "#[fg=${colors.overlay0}] #I:#W#{?@claude_waiting, 󰋼,} "
    set -g window-status-current-format "#[fg=${colors.blue},bg=${colors.base}]#[bg=${colors.blue},fg=${colors.base},bold] #I:#W #[fg=${colors.blue},bg=default]"
    set -g window-status-separator " "

    # Clear Claude waiting indicator on window focus
    set-hook -g pane-focus-in 'set-window-option @claude_waiting 0'

    # Pane borders
    set -g pane-border-style "fg=${colors.surface0}"
    set -g pane-active-border-style "fg=${colors.blue}"

    # ══════════════════════════════════════════════════════════════════════
    # Key Bindings
    # ══════════════════════════════════════════════════════════════════════

    # Reload config
    bind r source-file ~/.tmux.conf \; display "Config reloaded!"
    bind | split-window -h -c "#{pane_current_path}"
    bind - split-window -v -c "#{pane_current_path}"
    bind c new-window -c "#{pane_current_path}"
    bind , command-prompt -I "#W" "rename-window '%%'"
    bind $ command-prompt -I "#S" "rename-session '%%'"

    # Vim-style navigation
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R
    bind -r H resize-pane -L 5
    bind -r J resize-pane -D 5
    bind -r K resize-pane -U 5
    bind -r L resize-pane -R 5

    # Popup terminal
    bind p display-popup -E -w 80% -h 80% -d "#{pane_current_path}"
    bind s choose-tree -sZ
    bind Enter copy-mode
    bind S run-shell "${tmuxpExportScript}/bin/tmux-save-layout"

    # Copy mode
    bind -T copy-mode-vi v send -X begin-selection
    bind -T copy-mode-vi y send -X copy-selection-and-cancel

    # ══════════════════════════════════════════════════════════════════════
    # Plugins
    # ══════════════════════════════════════════════════════════════════════

    # Plugin path
    set-environment -g TMUX_PLUGIN_MANAGER_PATH "${pluginsDir}"

    ${lib.optionalString cfg.plugins.sensible ''
      # Sensible defaults
      run-shell ${pluginsDir}/tmux-sensible/sensible.tmux
    ''}

    ${lib.optionalString cfg.plugins.yank ''
      # Yank (clipboard)
      run-shell ${pluginsDir}/tmux-yank/yank.tmux
    ''}

    ${lib.optionalString cfg.plugins.resurrect ''
      # Resurrect (session persistence)
      set -g @resurrect-dir '${cfg.resurrectDir}'
      set -g @resurrect-capture-pane-contents 'on'
      # Disable process restoration strategies to avoid Nix path issues
      set -g @resurrect-strategy-ssh 'off'
      set -g @resurrect-strategy-mosh 'off'
      # Manual save/restore keybindings
      bind C-s run-shell "${pluginsDir}/tmux-resurrect/scripts/save.sh" \; display "Session saved"
      bind C-r run-shell "${pluginsDir}/tmux-resurrect/scripts/restore.sh" \; display "Session restored"
      run-shell ${pluginsDir}/tmux-resurrect/resurrect.tmux
    ''}

    ${lib.optionalString cfg.plugins.continuum ''
      # Continuum (auto-save)
      set -g @continuum-save-interval '${toString cfg.saveInterval}'
      set -g @continuum-restore 'off'
      run-shell ${pluginsDir}/tmux-continuum/continuum.tmux
    ''}

    ${lib.optionalString cfg.plugins.open ''
      # Open (URLs/files from copy mode)
      run-shell ${pluginsDir}/tmux-open/open.tmux
    ''}

    ${lib.optionalString cfg.plugins.sessionist ''
      # Sessionist (session management)
      run-shell ${pluginsDir}/tmux-sessionist/sessionist.tmux
    ''}

    ${lib.optionalString cfg.plugins.cowboy ''
      # Cowboy (kill unresponsive processes)
      run-shell ${pluginsDir}/tmux-cowboy/cowboy.tmux
    ''}

    ${lib.optionalString cfg.plugins.logging ''
      # Logging (pane capture)
      set -g @logging-path "${cfg.loggingPath}"
      run-shell ${pluginsDir}/tmux-logging/logging.tmux
    ''}

    ${lib.optionalString cfg.plugins.copycat ''
      # Copycat (regex search)
      run-shell ${pluginsDir}/tmux-copycat/copycat.tmux
    ''}

    ${lib.optionalString cfg.plugins.whichKey ''
      # Which-key (must load after other plugins for keybind discovery)
      set -g @tmux-which-key-xdg-enable 1
      set -g @tmux-which-key-disable-autobuild 1
      run-shell ${pluginsDir}/tmux-which-key/plugin.sh.tmux
    ''}

    ${lib.optionalString cfg.plugins.claudeMonitor ''
      # Auto-start Claude monitor (singleton - safe to call on every reload)
      run-shell -b '${claudeMonitorScript}/bin/tmux-claude-monitor &'
    ''}

    # ══════════════════════════════════════════════════════════════════════
    # Extra Configuration
    # ══════════════════════════════════════════════════════════════════════

    ${cfg.extraConfig}
  '';

in
{
  # ══════════════════════════════════════════════════════════════════════════
  # Module Options
  # ══════════════════════════════════════════════════════════════════════════

  options.z-tmux = {
    enable = lib.mkEnableOption "z-tmux configuration";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.tmux;
      defaultText = lib.literalExpression "pkgs.tmux";
      description = "The tmux package to use";
    };

    shell = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.zsh}/bin/zsh";
      defaultText = lib.literalExpression ''"''${pkgs.zsh}/bin/zsh"'';
      description = "Default shell for new tmux windows";
    };

    prefix = lib.mkOption {
      type = lib.types.str;
      default = "C-b";
      description = "Tmux prefix key";
    };

    catppuccinFlavor = lib.mkOption {
      type = lib.types.enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      default = "mocha";
      description = "Catppuccin flavor to use";
    };

    saveInterval = lib.mkOption {
      type = lib.types.int;
      default = 15;
      description = "Continuum auto-save interval in minutes";
    };

    enableMosh = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install mosh";
    };

    enableTmuxp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install tmuxp";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra tmux configuration appended to the config file";
    };

    workspacesDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/repos/workspaces";
      description = "Directory containing workspace repositories for the launcher";
    };

    resurrectDir = lib.mkOption {
      type = lib.types.str;
      default = "~/.tmux/resurrect";
      description = "Directory for tmux-resurrect session storage";
    };

    loggingPath = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.tmux/logs";
      description = "Directory for tmux-logging output";
    };

    tmuxpDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.config/tmuxp";
      description = "Directory for tmuxp session configurations";
    };

    # ════════════════════════════════════════════════════════════════════════
    # Plugin Options
    # ════════════════════════════════════════════════════════════════════════

    plugins = {
      sensible = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux-sensible (sensible defaults)";
      };

      yank = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux-yank (clipboard integration)";
      };

      resurrect = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux-resurrect (session persistence)";
      };

      continuum = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux-continuum (auto-save sessions)";
      };

      open = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux-open (open URLs/files from copy mode)";
      };

      sessionist = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux-sessionist (session management utilities)";
      };

      copycat = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux-copycat (regex search in scrollback)";
      };

      cowboy = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux-cowboy (kill unresponsive processes)";
      };

      logging = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux-logging (pane logging and capture)";
      };

      whichKey = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux-which-key (discoverable key bindings menu)";
      };

      prefixHighlight = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux-prefix-highlight (show prefix state in status)";
      };

      claudeMonitor = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Claude input monitoring (shows icon when Claude awaits input)";
      };
    };
  };

  # ══════════════════════════════════════════════════════════════════════════
  # Module Configuration
  # ══════════════════════════════════════════════════════════════════════════

  config = lib.mkIf cfg.enable {
    # Install packages
    home.packages = [
      cfg.package
      workspaceLauncher
      splitWindowScript
      claudeDevScript
      pkgs.reattach-to-user-namespace # macOS clipboard support
    ]
    ++ lib.optional cfg.enableTmuxp tmuxpLoader
    ++ lib.optional cfg.enableTmuxp tmuxpExportScript
    ++ lib.optional cfg.enableMosh pkgs.mosh
    ++ lib.optional cfg.enableTmuxp pkgs.tmuxp
    ++ lib.optional cfg.plugins.claudeMonitor claudeMonitorScript
    ++ lib.optional cfg.plugins.claudeMonitor claudeClearWaitingScript;

    # Create required directories (conditional on plugins)
    home.file.".tmux/resurrect/.keep" = lib.mkIf cfg.plugins.resurrect { text = ""; };
    home.file.".tmux/logs/.keep" = lib.mkIf cfg.plugins.logging { text = ""; };

    # Main tmux configuration (symlink to ~/.tmux.conf for reload-config)
    home.file.".tmux.conf".source = tmuxConf;

    # Which-key XDG config (config.yaml for reference)
    xdg.configFile."tmux/plugins/tmux-which-key/config.yaml" = lib.mkIf cfg.plugins.whichKey {
      source = whichKeyConfig;
    };

    # Which-key XDG data (pre-generated init.tmux)
    xdg.dataFile."tmux/plugins/tmux-which-key/init.tmux" = lib.mkIf cfg.plugins.whichKey {
      source = "${whichKeyInit}/init.tmux";
    };

    # tmuxp session configs
    xdg.configFile."tmuxp/.keep" = lib.mkIf cfg.enableTmuxp { text = ""; };

    # Remove existing .tmux.conf before home-manager creates symlink
    # This prevents "file in the way" errors when switching from manual config
    home.activation.cleanTmuxConf = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      if [ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
        $DRY_RUN_CMD rm -f "$HOME/.tmux.conf"
      fi
    '';

    # Clean up stale tmux sockets when version changes
    # This prevents "server exited unexpectedly" errors after tmux upgrades
    home.activation.cleanTmuxSockets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      TMUX_SOCKET_DIR="/tmp/tmux-$(id -u)"
      if [ -d "$TMUX_SOCKET_DIR" ] && ! ${cfg.package}/bin/tmux list-sessions &>/dev/null; then
        $DRY_RUN_CMD rm -rf "$TMUX_SOCKET_DIR"
        $VERBOSE_ECHO "Cleaned stale tmux sockets at $TMUX_SOCKET_DIR"
      fi
    '';

    # NOTE: We don't use programs.tmux because we need full control over plugin loading
    # and the Nix store paths. The config is managed via home.file instead.
  };
}
