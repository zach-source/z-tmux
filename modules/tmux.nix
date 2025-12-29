{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.z-tmux;

  # z-tmux version
  version = "0.2.22";

  # ══════════════════════════════════════════════════════════════════════════
  # Plugins from nixpkgs (properly packaged with patched shebangs)
  # ══════════════════════════════════════════════════════════════════════════

  plugins = {
    sensible = pkgs.tmuxPlugins.sensible;
    yank = pkgs.tmuxPlugins.yank;
    resurrect = pkgs.tmuxPlugins.resurrect;
    continuum = pkgs.tmuxPlugins.continuum;
    open = pkgs.tmuxPlugins.open;
    sessionist = pkgs.tmuxPlugins.sessionist;
    copycat = pkgs.tmuxPlugins.copycat;
    logging = pkgs.tmuxPlugins.logging;
    prefix-highlight = pkgs.tmuxPlugins.prefix-highlight;
    which-key = pkgs.tmuxPlugins.tmux-which-key;
    # cowboy not in nixpkgs - use mkTmuxPlugin
    cowboy = pkgs.tmuxPlugins.mkTmuxPlugin {
      pluginName = "cowboy";
      version = "unstable-2021-08-01";
      src = pkgs.fetchFromGitHub {
        owner = "tmux-plugins";
        repo = "tmux-cowboy";
        rev = "75702b6d0a866769dd14f3896e9d19f7e0acd4f2";
        sha256 = "sha256-KJNsdDLqT2Uzc25U4GLSB2O1SA/PThmDj9Aej5XjmJs=";
      };
      rtpFilePath = "cowboy.tmux";
    };
  };

  # Runtime dependencies for plugin scripts (ps, kill, grep, etc.)
  runtimeDeps = with pkgs; [
    coreutils
    procps
    gnugrep
    gawk
    gnused
    bash
    findutils
  ];
  runtimePath = pkgs.lib.makeBinPath runtimeDeps;

  # ══════════════════════════════════════════════════════════════════════════
  # Plugin Bundle (dynamic based on enabled plugins)
  # ══════════════════════════════════════════════════════════════════════════

  # Link to the actual plugin directories inside share/tmux-plugins/
  # This ensures TMUX_PLUGIN_MANAGER_PATH works correctly with TPM-style paths
  pluginsList =
    lib.optional cfg.plugins.sensible {
      name = "tmux-sensible";
      path = "${plugins.sensible}/share/tmux-plugins/sensible";
    }
    ++ lib.optional cfg.plugins.yank {
      name = "tmux-yank";
      path = "${plugins.yank}/share/tmux-plugins/yank";
    }
    ++ lib.optional cfg.plugins.resurrect {
      name = "tmux-resurrect";
      path = "${plugins.resurrect}/share/tmux-plugins/resurrect";
    }
    ++ lib.optional cfg.plugins.continuum {
      name = "tmux-continuum";
      path = "${plugins.continuum}/share/tmux-plugins/continuum";
    }
    ++ lib.optional cfg.plugins.prefixHighlight {
      name = "tmux-prefix-highlight";
      path = "${plugins.prefix-highlight}/share/tmux-plugins/prefix-highlight";
    }
    ++ lib.optional cfg.plugins.open {
      name = "tmux-open";
      path = "${plugins.open}/share/tmux-plugins/open";
    }
    ++ lib.optional cfg.plugins.sessionist {
      name = "tmux-sessionist";
      path = "${plugins.sessionist}/share/tmux-plugins/sessionist";
    }
    ++ lib.optional cfg.plugins.cowboy {
      name = "tmux-cowboy";
      path = "${plugins.cowboy}/share/tmux-plugins/cowboy";
    }
    ++ lib.optional cfg.plugins.logging {
      name = "tmux-logging";
      path = "${plugins.logging}/share/tmux-plugins/logging";
    }
    ++ lib.optional cfg.plugins.copycat {
      name = "tmux-copycat";
      path = "${plugins.copycat}/share/tmux-plugins/copycat";
    }
    ++ lib.optional cfg.plugins.whichKey {
      name = "tmux-which-key";
      path = "${plugins.which-key}/share/tmux-plugins/tmux-which-key";
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

    # Copy build.py and patch the import (using nixpkgs plugin path)
    sed 's/from pyyaml.lib import yaml/import yaml/' \
      ${plugins.which-key}/share/tmux-plugins/tmux-which-key/plugin/build.py > build.py

    ${pythonWithYaml}/bin/python3 build.py ${whichKeyConfig} $out/init.tmux

    # Fix: use global environment instead of session-hidden (avoids "no current session" warnings)
    sed -i 's/setenv -h/set-environment -g/g' $out/init.tmux

    # Remove noisy display messages
    sed -i '/display -p.*tmux-which-key/d' $out/init.tmux
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

  # Color palette shift for nested tmux sessions
  # mocha -> macchiato -> frappe -> latte -> mocha
  nestedFlavorMap = {
    mocha = "macchiato";
    macchiato = "frappe";
    frappe = "latte";
    latte = "mocha";
  };
  nestedFlavor = nestedFlavorMap.${cfg.catppuccinFlavor};
  nestedColors = catppuccinColors.${nestedFlavor};

  # ══════════════════════════════════════════════════════════════════════════
  # Tmux Configuration
  # ══════════════════════════════════════════════════════════════════════════

  tmuxConf = pkgs.writeText "tmux.conf" ''
    # ══════════════════════════════════════════════════════════════════════
    # z-tmux Configuration
    # Generated by home-manager z-tmux module
    # ══════════════════════════════════════════════════════════════════════

    # Default shell
    set -g default-shell ${cfg.shell}
    ${lib.optionalString pkgs.stdenv.isDarwin ''
      # macOS: use reattach-to-user-namespace for clipboard support
      set -g default-command "reattach-to-user-namespace -l ${cfg.shell}"
    ''}

    # Nested tmux detection
    # Check if we're inside another tmux and set @nested option
    if-shell '[ -n "$TMUX" ]' {
      set -g @nested 1
    } {
      set -g @nested 0
    }

    # Core settings
    set -g default-terminal "tmux-256color"
    set -ag terminal-overrides ",xterm-256color:RGB"
    set -as terminal-features ",xterm-256color:RGB"

    ${lib.optionalString cfg.enableRemoteClipboard ''
      # OSC 52 clipboard support for remote sessions
      # Enables copying to local clipboard when SSH'd into remote hosts
      set -g set-clipboard on
      set -as terminal-features ",xterm-256color:clipboard"
      # Allow tmux to set the terminal clipboard via OSC 52
      set -ag terminal-overrides ",xterm-256color:Ms=\\E]52;c;%p2%s\\7"
      set -ag terminal-overrides ",screen-256color:Ms=\\E]52;c;%p2%s\\7"
      set -ag terminal-overrides ",tmux-256color:Ms=\\E]52;c;%p2%s\\7"
    ''}

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
    # Remote/SSH Session Support
    # ══════════════════════════════════════════════════════════════════════

    # Update environment variables when attaching to existing sessions
    # This ensures SSH agent forwarding and display settings work correctly
    set -g update-environment "SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT SSH_TTY DISPLAY XAUTHORITY"

    # Detect SSH session and set @ssh option
    if-shell '[ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]' {
      set -g @ssh 1
    } {
      set -g @ssh 0
    }

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

    # Status left: session name with rounded powerline
    set -g status-left-length 50
    set -g status-left "#[fg=${colors.green},bg=default]#[fg=${colors.base},bg=${colors.green},bold]  #S #[fg=${colors.green},bg=default] "

    # Status right: N(nixVersion)|T(z-tmux version)|user@host with rounded powerline
    # Shows "nested" indicator with shifted color when inside another tmux
    set -g status-right-length 100
    set -g status-right "#{?@nested,#[fg=${nestedColors.peach},bg=default]#[fg=${nestedColors.base},bg=${nestedColors.peach},bold] 󰆘 nested #[fg=${nestedColors.peach},bg=default] ,}${
      if cfg.nixRepoVersion != null then
        "#[fg=${colors.peach}]N(${cfg.nixRepoVersion})#[fg=${colors.overlay0}]|"
      else
        ""
    }#[fg=${colors.yellow}]T(${version})#[fg=${colors.overlay0}]|#[fg=${colors.blue},bg=default]#[fg=${colors.base},bg=${colors.blue},bold]  $USER@#h #[fg=${colors.blue},bg=default]"

    # Window status with rounded tabs
    set -g window-status-format "#[fg=${colors.surface0},bg=default]#[fg=${colors.overlay0},bg=${colors.surface0}] #I:#W#{?@claude_waiting, 󰋼,} #[fg=${colors.surface0},bg=default]"
    set -g window-status-current-format "#[fg=${colors.blue},bg=default]#[fg=${colors.base},bg=${colors.blue},bold] #I:#W #[fg=${colors.blue},bg=default]"
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
    # Copy on mouse selection
    set -g @yank_selection_mouse 'clipboard'
    bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-selection-and-cancel

    # ══════════════════════════════════════════════════════════════════════
    # Plugins
    # ══════════════════════════════════════════════════════════════════════

    # Runtime PATH for plugin scripts (ps, kill, grep, etc.)
    set-environment -g PATH "${runtimePath}:$PATH"

    # Plugin path for compatibility
    set-environment -g TMUX_PLUGIN_MANAGER_PATH "${pluginsDir}"

    ${lib.optionalString cfg.plugins.sensible ''
      # Sensible defaults
      run-shell ${plugins.sensible}/share/tmux-plugins/sensible/sensible.tmux
    ''}

    ${lib.optionalString cfg.plugins.yank ''
      # Yank (clipboard)
      run-shell ${plugins.yank}/share/tmux-plugins/yank/yank.tmux
    ''}

    ${lib.optionalString cfg.plugins.resurrect ''
      # Resurrect (session persistence)
      set -g @resurrect-dir '${cfg.resurrectDir}'
      set -g @resurrect-capture-pane-contents 'on'
      # Disable process restoration strategies to avoid Nix path issues
      set -g @resurrect-strategy-ssh 'off'
      set -g @resurrect-strategy-mosh 'off'
      # Manual save/restore keybindings
      bind C-s run-shell "${plugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh" \; display "Session saved"
      bind C-r run-shell "${plugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh" \; display "Session restored"
      run-shell ${plugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux
    ''}

    ${lib.optionalString cfg.plugins.continuum ''
      # Continuum (auto-save)
      set -g @continuum-save-interval '${toString cfg.saveInterval}'
      set -g @continuum-restore 'off'
      run-shell ${plugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
    ''}

    ${lib.optionalString cfg.plugins.open ''
      # Open (URLs/files from copy mode)
      run-shell ${plugins.open}/share/tmux-plugins/open/open.tmux
    ''}

    ${lib.optionalString cfg.plugins.sessionist ''
      # Sessionist (session management)
      run-shell ${plugins.sessionist}/share/tmux-plugins/sessionist/sessionist.tmux
    ''}

    ${lib.optionalString cfg.plugins.cowboy ''
      # Cowboy (kill unresponsive processes)
      run-shell ${plugins.cowboy}/share/tmux-plugins/cowboy/cowboy.tmux
    ''}

    ${lib.optionalString cfg.plugins.logging ''
      # Logging (pane capture)
      set -g @logging-path "${cfg.loggingPath}"
      run-shell ${plugins.logging}/share/tmux-plugins/logging/logging.tmux
    ''}

    ${lib.optionalString cfg.plugins.copycat ''
      # Copycat (regex search)
      run-shell ${plugins.copycat}/share/tmux-plugins/copycat/copycat.tmux
    ''}

    ${lib.optionalString cfg.plugins.whichKey ''
      # Which-key (source our pre-built init.tmux directly)
      # We don't use plugin.sh.tmux because it looks for init.tmux in the Nix store
      source-file ~/.tmux/plugins/tmux-which-key/init.tmux
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

    enableRemoteClipboard = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable OSC 52 clipboard support for copying from remote SSH sessions.
        This allows clipboard integration when SSH'd into remote hosts.
        Requires a terminal that supports OSC 52 (iTerm2, Alacritty, Kitty, etc.)
      '';
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

    nixRepoVersion = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Version string of your Nix home repository to display in the status bar.
        When set, displays as "N(version)" in the right status.
        When null, this section is omitted entirely.
      '';
      example = "v1.2.3";
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
    ]
    ++ lib.optional pkgs.stdenv.isDarwin pkgs.reattach-to-user-namespace
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

    # Which-key config and init (traditional ~/.tmux/ paths)
    home.file.".tmux/plugins/tmux-which-key/config.yaml" = lib.mkIf cfg.plugins.whichKey {
      source = whichKeyConfig;
    };
    home.file.".tmux/plugins/tmux-which-key/init.tmux" = lib.mkIf cfg.plugins.whichKey {
      source = "${whichKeyInit}/init.tmux";
    };

    # tmuxp session configs
    home.file.".config/tmuxp/.keep" = lib.mkIf cfg.enableTmuxp { text = ""; };

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
