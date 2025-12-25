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

          # Plugin sources
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

          pluginsDir = pkgs.linkFarm "tmux-plugins" [
            {
              name = "tpm";
              path = tpm;
            }
            {
              name = "tmux-resurrect";
              path = tmuxResurrect;
            }
            {
              name = "tmux-continuum";
              path = tmuxContinuum;
            }
            {
              name = "tmux-sensible";
              path = tmuxSensible;
            }
            {
              name = "tmux-yank";
              path = tmuxYank;
            }
            {
              name = "tmux-prefix-highlight";
              path = tmuxPrefixHighlight;
            }
            {
              name = "tmux-which-key";
              path = tmuxWhichKey;
            }
            {
              name = "tmux-open";
              path = tmuxOpen;
            }
            {
              name = "tmux-sessionist";
              path = tmuxSessionist;
            }
            {
              name = "tmux-cowboy";
              path = tmuxCowboy;
            }
            {
              name = "tmux-logging";
              path = tmuxLogging;
            }
            {
              name = "tmux-copycat";
              path = tmuxCopycat;
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

              # Change to workspace and launch claude-dev
              cd "$WORKSPACE" && tmux-claude-dev
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

            mkdir -p "$TMUXP_DIR"

            if command -v tmuxp >/dev/null 2>&1; then
              tmuxp freeze -o "$OUTPUT_FILE" -y
              tmux display-message "Session saved to $OUTPUT_FILE"
            else
              tmux display-message "tmuxp not found!"
            fi
          '';

          splitWindowScript = pkgs.writeShellScriptBin "tmux-split-window" ''
            #!/usr/bin/env bash
            TMUX_BIN="$(command -v tmux)"
            WINDOW_NAME="''${1:-split}"
            WORK_DIR="$(pwd)"
            "$TMUX_BIN" new-window -n "$WINDOW_NAME" -c "$WORK_DIR" \; \
              split-window -h -c "$WORK_DIR" \; \
              select-pane -L
          '';

          claudeDevScript = pkgs.writeShellScriptBin "tmux-claude-dev" ''
            #!/usr/bin/env bash
            TMUX_BIN="$(command -v tmux)"
            WORK_DIR="$(pwd)"
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

          # Which-key configuration
          whichKeyConfig = ./tmux/which-key-config.yaml;

          pythonWithYaml = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);

          whichKeyInit = pkgs.runCommand "which-key-init" { } ''
            mkdir -p $out

            sed 's/from pyyaml.lib import yaml/import yaml/' \
              ${pluginsDir}/tmux-which-key/plugin/build.py > build.py

            ${pythonWithYaml}/bin/python3 build.py ${whichKeyConfig} $out/init.tmux
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
            set -g default-terminal "tmux-256color"
            set -ag terminal-overrides ",xterm-256color:RGB"
            set -as terminal-features ",xterm-256color:RGB"
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

            # Status bar
            set -g status on
            set -g status-position top
            set -g status-interval 5
            set -g status-style "bg=default"
            set -g status-left-length 50
            set -g status-left "#[fg=${colors.base},bg=${colors.green},bold]  #S #[fg=${colors.green},bg=default]"
            set -g status-right-length 100
            set -g status-right "#[fg=${colors.blue}]#[fg=${colors.base},bg=${colors.blue},bold] 󰉋 #{=30:pane_current_path} "
            set -g window-status-format "#[fg=${colors.overlay0}] #I:#W "
            set -g window-status-current-format "#[fg=${colors.blue},bg=${colors.base}]#[bg=${colors.blue},fg=${colors.base},bold] #I:#W #[fg=${colors.blue},bg=default]"
            set -g window-status-separator " "
            set -g pane-border-style "fg=${colors.surface0}"
            set -g pane-active-border-style "fg=${colors.blue}"

            # Key bindings
            bind r source-file ~/.tmux.conf \; display "Config reloaded!"
            bind | split-window -h -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"
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
            bind -T copy-mode-vi y send -X copy-selection-and-cancel

            # Plugins
            set-environment -g TMUX_PLUGIN_MANAGER_PATH "${pluginsDir}"
            run-shell ${pluginsDir}/tmux-sensible/sensible.tmux
            run-shell ${pluginsDir}/tmux-yank/yank.tmux

            # Resurrect (configurable via ZTMUX_RESURRECT_DIR env var)
            set -g @resurrect-dir "$ZTMUX_RESURRECT_DIR"
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-strategy-ssh 'off'
            set -g @resurrect-strategy-mosh 'off'
            bind C-s run-shell "${pluginsDir}/tmux-resurrect/scripts/save.sh" \; display "Session saved"
            bind C-r run-shell "${pluginsDir}/tmux-resurrect/scripts/restore.sh" \; display "Session restored"
            run-shell ${pluginsDir}/tmux-resurrect/resurrect.tmux

            # Continuum
            set -g @continuum-save-interval '15'
            set -g @continuum-restore 'off'
            run-shell ${pluginsDir}/tmux-continuum/continuum.tmux

            # High value plugins
            run-shell ${pluginsDir}/tmux-open/open.tmux
            run-shell ${pluginsDir}/tmux-sessionist/sessionist.tmux

            # Optional plugins
            run-shell ${pluginsDir}/tmux-cowboy/cowboy.tmux
            set -g @logging-path "$ZTMUX_LOGGING_PATH"
            run-shell ${pluginsDir}/tmux-logging/logging.tmux
            run-shell ${pluginsDir}/tmux-copycat/copycat.tmux

            # Which-key
            set -g @tmux-which-key-xdg-enable 1
            set -g @tmux-which-key-disable-autobuild 1
            run-shell ${pluginsDir}/tmux-which-key/plugin.sh.tmux
          '';

        in
        {
          default = self.packages.${system}.test;

          # Test package for trying out the configuration
          test = pkgs.writeShellScriptBin "z-tmux-test" ''
            export TMUX_PLUGIN_MANAGER_PATH="${pluginsDir}"
            export PATH="${workspaceLauncher}/bin:${tmuxpLoader}/bin:${tmuxpExportScript}/bin:${splitWindowScript}/bin:${claudeDevScript}/bin:$PATH"

            # Configurable paths (override via ZTMUX_* environment variables)
            export ZTMUX_WORKSPACES_DIR="''${ZTMUX_WORKSPACES_DIR:-$HOME/repos/workspaces}"
            export ZTMUX_TMUXP_DIR="''${ZTMUX_TMUXP_DIR:-$HOME/.config/tmuxp}"
            export ZTMUX_RESURRECT_DIR="''${ZTMUX_RESURRECT_DIR:-$HOME/.tmux/resurrect}"
            export ZTMUX_LOGGING_PATH="''${ZTMUX_LOGGING_PATH:-$HOME/.tmux/logs}"

            if [ -n "$TMUX" ]; then
              echo "Already in tmux. Run: tmux source-file ~/.tmux.conf"
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

            # Set up which-key
            TEST_DIR="$HOME/.cache/z-tmux-test"
            export XDG_CONFIG_HOME="$TEST_DIR/config"
            export XDG_DATA_HOME="$TEST_DIR/data"
            WHICH_KEY_CONFIG="$XDG_CONFIG_HOME/tmux/plugins/tmux-which-key"
            WHICH_KEY_DATA="$XDG_DATA_HOME/tmux/plugins/tmux-which-key"
            mkdir -p "$WHICH_KEY_CONFIG" "$WHICH_KEY_DATA"

            cp -f ${whichKeyConfig} "$WHICH_KEY_CONFIG/config.yaml"
            cp -f ${whichKeyInit}/init.tmux "$WHICH_KEY_DATA/init.tmux"

            # Symlink config for reload-config
            ln -sf ${tmuxConfNix} "$HOME/.tmux.conf"

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
