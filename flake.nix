{
  description = "Reproducible tmux setup with Catppuccin, tmuxp, and session persistence";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # ════════════════════════════════════════════════════════════════════════
      # Home Manager Module
      # ════════════════════════════════════════════════════════════════════════

      homeManagerModules = {
        default = self.homeManagerModules.z-tmux;
        z-tmux = import ./modules/tmux.nix;
      };

      # ════════════════════════════════════════════════════════════════════════
      # Development Shell
      # ════════════════════════════════════════════════════════════════════════

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              tmux
              tmuxp
              mosh
              fzf
              zoxide
            ];
          };
        }
      );

      # ════════════════════════════════════════════════════════════════════════
      # Example Home Manager Configuration
      # ════════════════════════════════════════════════════════════════════════

      homeConfigurations = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          "z-tmux" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              self.homeManagerModules.z-tmux
              {
                home = {
                  username = "user";
                  homeDirectory = if pkgs.stdenv.isDarwin then "/Users/user" else "/home/user";
                  stateVersion = "24.11";
                };

                programs.home-manager.enable = true;

                # Enable the tmux module
                z-tmux.enable = true;
              }
            ];
          };
        }
      );

      # ════════════════════════════════════════════════════════════════════════
      # Test Package (standalone, without full home-manager activation)
      # ════════════════════════════════════════════════════════════════════════

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # ════════════════════════════════════════════════════════════════════════
          # Plugins from nixpkgs (properly packaged with patched shebangs)
          # ════════════════════════════════════════════════════════════════════════
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
            # tmux-which-key from nixpkgs
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

          # Plugin directory for TMUX_PLUGIN_MANAGER_PATH compatibility
          pluginsDir = pkgs.linkFarm "tmux-plugins" [
            {
              name = "tmux-sensible";
              path = plugins.sensible;
            }
            {
              name = "tmux-yank";
              path = plugins.yank;
            }
            {
              name = "tmux-resurrect";
              path = plugins.resurrect;
            }
            {
              name = "tmux-continuum";
              path = plugins.continuum;
            }
            {
              name = "tmux-open";
              path = plugins.open;
            }
            {
              name = "tmux-sessionist";
              path = plugins.sessionist;
            }
            {
              name = "tmux-copycat";
              path = plugins.copycat;
            }
            {
              name = "tmux-logging";
              path = plugins.logging;
            }
            {
              name = "tmux-prefix-highlight";
              path = plugins.prefix-highlight;
            }
            {
              name = "tmux-which-key";
              path = plugins.which-key;
            }
            {
              name = "tmux-cowboy";
              path = plugins.cowboy;
            }
          ];

          # Helper scripts
          workspaceLauncher = pkgs.writeShellScriptBin "tmux-workspace" ''
            #!/usr/bin/env bash
            # Configure via z-tmux.workspacesDir in home-manager module
            WORKSPACES_DIR="''${ZTMUX_WORKSPACES_DIR:-$HOME/repos/workspaces}"

            if [ ! -d "$WORKSPACES_DIR" ]; then
              echo "Workspaces directory not found: $WORKSPACES_DIR"
              exit 1
            fi

            ALL_WORKSPACES=$(find "$WORKSPACES_DIR" -maxdepth 2 -type d -name ".git" 2>/dev/null | \
              xargs -I{} dirname {} | sort)

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

              # Schedule the window creation in the main session (not the popup)
              # Using run-shell -b runs it in background after popup closes
              tmux run-shell -b "cd '$WORKSPACE' && tmux-claude-dev"
            fi
          '';

          tmuxpLoader = pkgs.writeShellScriptBin "tmuxp-loader" ''
            #!/usr/bin/env bash
            TMUXP_DIR="''${ZTMUX_TMUXP_DIR:-$HOME/.config/tmuxp}"

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

          tmuxpExportScript = pkgs.writeShellScriptBin "tmux-save-layout" ''
            #!/usr/bin/env bash
            SESSION_NAME=$(tmux display-message -p '#S')
            TMUXP_DIR="''${ZTMUX_TMUXP_DIR:-$HOME/.config/tmuxp}"
            OUTPUT_FILE="$TMUXP_DIR/$SESSION_NAME.yaml"
            TEMP_FILE=$(mktemp)

            mkdir -p "$TMUXP_DIR"

            if ! command -v tmuxp >/dev/null 2>&1; then
              tmux display-message "tmuxp not found!"
              exit 1
            fi

            # Freeze the session
            tmuxp freeze -o "$TEMP_FILE" -y

            # Clean up claude version-specific commands
            # Claude runs as: /nix/store/xxx-claude-code-xxx/bin/claude or similar
            # Replace with generic "claude" or "claude-smart" command
            ${pkgs.gnused}/bin/sed -i \
              -e 's|/nix/store/[^/]*/bin/claude[^ ]*|claude|g' \
              -e 's|shell_command: claude [0-9.]*|shell_command: claude|g' \
              -e 's|shell_command:.*claude-code.*/bin/claude.*|shell_command: claude|g' \
              "$TEMP_FILE"

            mv "$TEMP_FILE" "$OUTPUT_FILE"
            tmux display-message "Session saved to $OUTPUT_FILE (claude paths normalized)"
          '';

          splitWindowScript = pkgs.writeShellScriptBin "tmux-split-window" ''
            #!/usr/bin/env bash
            # Uses pane_current_path instead of pwd (works correctly from run-shell)
            TMUX_BIN="$(command -v tmux)"
            WINDOW_NAME="''${1:-split}"
            WORK_DIR="$("$TMUX_BIN" display-message -p '#{pane_current_path}')"
            "$TMUX_BIN" new-window -n "$WINDOW_NAME" -c "$WORK_DIR" \; \
              split-window -h -c "$WORK_DIR" \; \
              select-pane -L
          '';

          claudeDevScript = pkgs.writeShellScriptBin "tmux-claude-dev" ''
            #!/usr/bin/env bash
            # Uses pane_current_path instead of pwd (works correctly from run-shell)
            TMUX_BIN="$(command -v tmux)"
            WORK_DIR="$("$TMUX_BIN" display-message -p '#{pane_current_path}')"
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

              # Check for Claude's waiting prompt patterns:
              # - Line starting with > (Claude's input prompt)
              # - "Waiting for your" pattern
              # - Empty line after output indicating ready for input
              if echo "$content" | grep -qE '^\s*>\s*$|^>\s|Waiting for|waiting for your|^claude>|Human:.*$'; then
                echo "waiting"
                return 0
              fi

              echo "active"
              return 1
            }

            # Main monitoring loop
            while true; do
              # Get all panes
              tmux list-panes -a -F '#{pane_id} #{window_id} #{window_name}' 2>/dev/null | while read -r pane_id window_id window_name; do
                # Only check panes that might have claude (claude-dev windows or panes running claude)
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

          # Script to clear claude waiting indicator on focus
          claudeClearWaitingScript = pkgs.writeShellScriptBin "tmux-claude-clear-waiting" ''
            #!/usr/bin/env bash
            # Clear the waiting indicator for the current window
            tmux set-window-option @claude_waiting 0 2>/dev/null
          '';

          # Which-key configuration
          whichKeyConfig = ./tmux/which-key-config.yaml;

          pythonWithYaml = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);

          whichKeyInit = pkgs.runCommand "which-key-init" { } ''
            mkdir -p $out

            sed 's/from pyyaml.lib import yaml/import yaml/' \
              ${plugins.which-key}/share/tmux-plugins/tmux-which-key/plugin/build.py > build.py

            ${pythonWithYaml}/bin/python3 build.py ${whichKeyConfig} $out/init.tmux

            # Fix: use global environment instead of session-hidden (avoids "no current session" warnings)
            sed -i 's/setenv -h/set-environment -g/g' $out/init.tmux

            # Remove noisy display messages
            sed -i '/display -p.*tmux-which-key/d' $out/init.tmux
          '';

          # Catppuccin mocha colors
          colors = {
            base = "#1e1e2e";
            surface0 = "#313244";
            overlay0 = "#6c7086";
            blue = "#89b4fa";
            green = "#a6e3a1";
            peach = "#fab387";
            yellow = "#f9e2af";
            red = "#f38ba8";
          };

          # Full tmux configuration
          tmuxConfNix = pkgs.writeText "tmux.conf" ''
            # z-tmux test configuration
            set -g default-shell $SHELL
            set -g default-command "${pkgs.reattach-to-user-namespace}/bin/reattach-to-user-namespace -l $SHELL"
            set -g default-terminal "tmux-256color"
            set -ag terminal-overrides ",xterm-256color:RGB"
            set -as terminal-features ",xterm-256color:RGB"

            # OSC 52 clipboard support for remote sessions
            set -g set-clipboard external
            set -g allow-passthrough on
            set -as terminal-features ",xterm-256color:clipboard"
            set -ag terminal-overrides ",xterm-256color:Ms=\\E]52;c;%p2%s\\7"
            set -ag terminal-overrides ",screen-256color:Ms=\\E]52;c;%p2%s\\7"
            set -ag terminal-overrides ",tmux-256color:Ms=\\E]52;c;%p2%s\\7"

            set -g prefix C-b
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

            # Remote/SSH session support
            set -g update-environment "SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT SSH_TTY DISPLAY XAUTHORITY"
            if-shell '[ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]' {
              set -g @ssh 1
            } {
              set -g @ssh 0
            }

            # Status bar
            set -g status on
            set -g status-position top
            set -g status-interval 5
            set -g status-style "bg=default"
            set -g status-left-length 50
            set -g status-left "#[fg=${colors.base},bg=${colors.green},bold]  #S #[fg=${colors.green},bg=default]"
            set -g status-right-length 120
            set -g status-right "#[fg=${colors.peach}]D(test-dotfiles)#[fg=${colors.overlay0}]|#[fg=${colors.green}]N(test-nvim)#[fg=${colors.overlay0}]|#[fg=${colors.yellow}]T(0.2.31)#[fg=${colors.overlay0}]|#[fg=${colors.blue},bg=default]#[fg=${colors.base},bg=${colors.blue},bold]  $USER@#h #[fg=${colors.blue},bg=default]"
            set -g window-status-format "#[fg=${colors.overlay0}]#I:#W#{?@claude_waiting, 󰋼,}"
            set -g window-status-current-format "#[fg=${colors.blue},bg=${colors.base}]#[bg=${colors.blue},fg=${colors.base},bold] #I:#W #[fg=${colors.blue},bg=default]"
            set -g window-status-separator "  "

            # Clear claude waiting indicator on window focus
            set-hook -g pane-focus-in 'set-window-option @claude_waiting 0'
            set -g pane-border-style "fg=${colors.surface0}"
            set -g pane-active-border-style "fg=${colors.blue}"

            # Key bindings
            bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
            bind | split-window -h -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"
            bind % split-window -h -c "#{pane_current_path}"
            bind '"' split-window -v -c "#{pane_current_path}"
            bind c new-window -c "#{pane_current_path}"
            bind , command-prompt -I "#W" "rename-window '%%'"
            bind $ command-prompt -I "#S" "rename-session '%%'"
            bind h select-pane -L
            bind j select-pane -D
            bind k select-pane -U
            bind l select-pane -R
            bind -r H resize-pane -L 5
            bind -r J resize-pane -D 5
            bind -r K resize-pane -U 5
            bind -r L resize-pane -R 5
            bind p display-popup -E -w 80% -h 80% -d "#{pane_current_path}"
            bind s choose-tree -sZ
            bind Enter copy-mode
            bind S run-shell "${tmuxpExportScript}/bin/tmux-save-layout"
            bind -T copy-mode-vi v send -X begin-selection
            bind -T copy-mode-vi C-v send -X rectangle-toggle
            bind -T copy-mode-vi y send -X copy-pipe-and-cancel
            bind -T copy-mode-vi Y send -X copy-end-of-line-and-cancel
            bind -T copy-mode-vi q send -X cancel
            bind -T copy-mode-vi Escape send -X cancel
            # Copy on mouse selection (uses OSC 52 via set-clipboard external)
            bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel

            # Runtime PATH for plugin scripts (ps, kill, grep, etc.)
            # Note: set-environment only affects new panes, so we also prepend PATH in run-shell commands
            set-environment -g PATH "${runtimePath}:$PATH"

            # Plugins (using nixpkgs tmuxPlugins with proper paths)
            set-environment -g TMUX_PLUGIN_MANAGER_PATH "${pluginsDir}"
            run-shell "PATH=${runtimePath}:$PATH ${plugins.sensible}/share/tmux-plugins/sensible/sensible.tmux"
            run-shell "PATH=${runtimePath}:$PATH ${plugins.yank}/share/tmux-plugins/yank/yank.tmux"

            # Resurrect (configurable via ZTMUX_RESURRECT_DIR env var)
            set -g @resurrect-dir "$ZTMUX_RESURRECT_DIR"
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-strategy-ssh 'off'
            set -g @resurrect-strategy-mosh 'off'
            bind C-s run-shell "PATH=${runtimePath}:$PATH ${plugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh" \; display "Session saved"
            bind C-r run-shell "PATH=${runtimePath}:$PATH ${plugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh" \; display "Session restored"
            run-shell "PATH=${runtimePath}:$PATH ${plugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux"

            # Continuum
            set -g @continuum-save-interval '15'
            set -g @continuum-restore 'off'
            run-shell "PATH=${runtimePath}:$PATH ${plugins.continuum}/share/tmux-plugins/continuum/continuum.tmux"

            # High value plugins
            run-shell "PATH=${runtimePath}:$PATH ${plugins.open}/share/tmux-plugins/open/open.tmux"
            run-shell "PATH=${runtimePath}:$PATH ${plugins.sessionist}/share/tmux-plugins/sessionist/sessionist.tmux"

            # Optional plugins
            run-shell "PATH=${runtimePath}:$PATH ${plugins.cowboy}/share/tmux-plugins/cowboy/cowboy.tmux"
            set -g @logging-path "$ZTMUX_LOGGING_PATH"
            run-shell "PATH=${runtimePath}:$PATH ${plugins.logging}/share/tmux-plugins/logging/logging.tmux"
            run-shell "PATH=${runtimePath}:$PATH ${plugins.copycat}/share/tmux-plugins/copycat/copycat.tmux"

            # Which-key (source our pre-built init.tmux directly)
            # We don't use plugin.sh.tmux because it looks for init.tmux in the Nix store
            source-file ~/.tmux/plugins/tmux-which-key/init.tmux

            # Auto-start Claude monitor (singleton - safe to call on every reload)
            run-shell -b '${claudeMonitorScript}/bin/tmux-claude-monitor &'
          '';

          # Test script for validating features
          testScript = pkgs.writeShellScriptBin "z-tmux-test-features" ''
            ${builtins.readFile ./tests/test-features.sh}
          '';

        in
        {
          default = self.packages.${system}.test;

          # Feature test suite (run inside tmux)
          test-features = testScript;

          # Test package for trying out the configuration
          test = pkgs.writeShellScriptBin "z-tmux-test" ''
            export TMUX_PLUGIN_MANAGER_PATH="${pluginsDir}"
            export PATH="${workspaceLauncher}/bin:${tmuxpLoader}/bin:${tmuxpExportScript}/bin:${splitWindowScript}/bin:${claudeDevScript}/bin:${claudeMonitorScript}/bin:${claudeClearWaitingScript}/bin:${testScript}/bin:$PATH"

            # Configurable paths (override via ZTMUX_* environment variables)
            export ZTMUX_WORKSPACES_DIR="''${ZTMUX_WORKSPACES_DIR:-$HOME/repos/workspaces}"
            export ZTMUX_TMUXP_DIR="''${ZTMUX_TMUXP_DIR:-$HOME/.config/tmuxp}"
            export ZTMUX_RESURRECT_DIR="''${ZTMUX_RESURRECT_DIR:-$HOME/.tmux/resurrect}"
            export ZTMUX_LOGGING_PATH="''${ZTMUX_LOGGING_PATH:-$HOME/.tmux/logs}"

            if [ -n "$TMUX" ]; then
              echo "Already in tmux. Run: tmux source-file ~/.config/tmux/tmux.conf"
              exit 1
            fi

            TMUX_BIN="$(command -v tmux)"
            if [ -z "$TMUX_BIN" ]; then
              echo "Error: tmux not found in PATH"
              exit 1
            fi

            ZSH_BIN="$(command -v zsh)"
            if [ -n "$ZSH_BIN" ]; then
              export SHELL="$ZSH_BIN"
            fi

            # Set up which-key in traditional ~/.tmux/ location
            WHICH_KEY_DIR="$HOME/.tmux/plugins/tmux-which-key"
            mkdir -p "$WHICH_KEY_DIR"

            cp -f ${whichKeyConfig} "$WHICH_KEY_DIR/config.yaml"
            cp -f ${whichKeyInit}/init.tmux "$WHICH_KEY_DIR/init.tmux"

            # Symlink config for reload-config (XDG path)
            mkdir -p "$HOME/.config/tmux"
            ln -sf ${tmuxConfNix} "$HOME/.config/tmux/tmux.conf"

            if [ $# -eq 0 ]; then
              exec "$TMUX_BIN" -f ${tmuxConfNix} new-session -s main "$SHELL"
            else
              exec "$TMUX_BIN" -f ${tmuxConfNix} "$@"
            fi
          '';
        }
      );
    };
}
