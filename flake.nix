{
  description = "Reproducible tmux setup with Catppuccin, tmuxp, and session persistence";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      catppuccin,
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

      # TPM (Tmux Plugin Manager)
      tpm =
        pkgs:
        pkgs.fetchFromGitHub {
          owner = "tmux-plugins";
          repo = "tpm";
          rev = "v3.1.0";
          sha256 = "sha256-CeI9Wq6tHqV68woE11lIY4cLoNY8XWyXyMHTDmFKJKI=";
        };

      # tmux-resurrect
      tmuxResurrect =
        pkgs:
        pkgs.fetchFromGitHub {
          owner = "tmux-plugins";
          repo = "tmux-resurrect";
          rev = "v4.0.0";
          sha256 = "sha256-44Ok7TbNfssMoBmOAqLLOj7oYRG3AQWrCuLzP8tA8Kg=";
        };

      # tmux-continuum
      tmuxContinuum =
        pkgs:
        pkgs.fetchFromGitHub {
          owner = "tmux-plugins";
          repo = "tmux-continuum";
          rev = "v3.1.0";
          sha256 = "sha256-e02cshLR9a2+uhrU/oew+FPTKhd4mi0/Q02ToHbbVrE=";
        };

      # tmux-sensible
      tmuxSensible =
        pkgs:
        pkgs.fetchFromGitHub {
          owner = "tmux-plugins";
          repo = "tmux-sensible";
          rev = "v3.0.0";
          sha256 = "sha256-ney/Y1YtCsWLgthOmoYGZTpPfJz+DravRB31YZgnDuU=";
        };

      # tmux-yank
      tmuxYank =
        pkgs:
        pkgs.fetchFromGitHub {
          owner = "tmux-plugins";
          repo = "tmux-yank";
          rev = "v2.3.0";
          sha256 = "sha256-DQQCsBHxOo/BepclkICCtVUAL4pozS/RTJBcVLzICns=";
        };

      # tmux-prefix-highlight
      tmuxPrefixHighlight =
        pkgs:
        pkgs.fetchFromGitHub {
          owner = "tmux-plugins";
          repo = "tmux-prefix-highlight";
          rev = "06cbb4ecd3a0a918ce355c70dc56d79debd455c7";
          sha256 = "sha256-wkMm2Myxau24E0fbXINPuL2dc8E4ZYe5Pa6A0fWhiw4=";
        };
    in
    {
      # Standalone Home Manager module
      homeManagerModules = {
        default = self.homeManagerModules.z-tmux;
        z-tmux = import ./modules/tmux.nix;
      };

      # Development shell for testing
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
            ];
          };
        }
      );

      # Example standalone Home Manager configuration
      homeConfigurations = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          "z-tmux" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              catppuccin.homeManagerModules.catppuccin
              self.homeManagerModules.z-tmux
              {
                home = {
                  username = "ztaylor";
                  homeDirectory = if pkgs.stdenv.isDarwin then "/Users/ztaylor" else "/home/ztaylor";
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

      # Packages for testing
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # Bundle all plugins into a single directory
          pluginsDir = pkgs.linkFarm "tmux-plugins" [
            {
              name = "tpm";
              path = tpm pkgs;
            }
            {
              name = "tmux-resurrect";
              path = tmuxResurrect pkgs;
            }
            {
              name = "tmux-continuum";
              path = tmuxContinuum pkgs;
            }
            {
              name = "tmux-sensible";
              path = tmuxSensible pkgs;
            }
            {
              name = "tmux-yank";
              path = tmuxYank pkgs;
            }
            {
              name = "tmux-prefix-highlight";
              path = tmuxPrefixHighlight pkgs;
            }
          ];

          # Config that uses nix-managed plugins (no TPM needed at runtime)
          tmuxConfNix = pkgs.writeText "tmux.conf" ''
            # z-tmux: Nix-managed configuration (plugins pre-installed)

            # Core settings
            unbind C-b
            set -g prefix C-a
            bind C-a send-prefix

            set -g default-terminal "tmux-256color"
            set -ag terminal-overrides ",xterm-256color:RGB"
            set -g mouse on
            set -g history-limit 50000
            set -g base-index 1
            setw -g pane-base-index 1
            set -g renumber-windows on
            set -sg escape-time 0
            setw -g mode-keys vi
            set -g focus-events on

            # Status bar - Catppuccin Mocha
            set -g status-position top
            set -g status-interval 5
            set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
            set -g status-left-length 50
            set -g status-left "#[bg=#cba6f7,fg=#1e1e2e,bold]  #S #[bg=#1e1e2e,fg=#cba6f7]"
            set -g status-right-length 100
            set -g status-right "#{?client_prefix,#[bg=#a6e3a1,fg=#1e1e2e] PREFIX #[bg=#1e1e2e,fg=#a6e3a1],}#[fg=#313244]#[bg=#313244,fg=#cdd6f4]  %H:%M #[fg=#89b4fa]#[bg=#89b4fa,fg=#1e1e2e,bold] %d-%b "
            set -g window-status-format "#[fg=#1e1e2e,bg=#313244]#[bg=#313244,fg=#cdd6f4] #I:#W #[fg=#313244,bg=#1e1e2e]"
            set -g window-status-current-format "#[fg=#1e1e2e,bg=#89b4fa]#[bg=#89b4fa,fg=#1e1e2e,bold] #I:#W #[fg=#89b4fa,bg=#1e1e2e]"
            set -g pane-border-style "fg=#313244"
            set -g pane-active-border-style "fg=#89b4fa"

            # Key bindings
            bind r source-file ~/.tmux.conf \; display "Config reloaded!"
            bind | split-window -h -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"
            bind c new-window -c "#{pane_current_path}"
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

            # Copy mode
            bind -T copy-mode-vi v send -X begin-selection
            bind -T copy-mode-vi y send -X copy-selection-and-cancel

            # Plugin configuration
            set -g @resurrect-capture-pane-contents 'on'
            set -g @continuum-save-interval '15'
            set -g @continuum-restore 'on'

            # Load plugins from Nix store
            run-shell ${pluginsDir}/tmux-sensible/sensible.tmux
            run-shell ${pluginsDir}/tmux-yank/yank.tmux
            run-shell ${pluginsDir}/tmux-prefix-highlight/prefix_highlight.tmux
            run-shell ${pluginsDir}/tmux-resurrect/resurrect.tmux
            run-shell ${pluginsDir}/tmux-continuum/continuum.tmux
          '';
        in
        {
          default = self.packages.${system}.test;

          # Standalone tmux.conf (for manual TPM usage)
          tmux-config = pkgs.writeTextFile {
            name = "tmux.conf";
            text = builtins.readFile ./tmux/tmux.conf;
          };

          # Pre-bundled plugins directory
          plugins = pluginsDir;

          # Nix-managed config (no TPM needed)
          config-nix = tmuxConfNix;

          # Test script - runs tmux with everything pre-configured
          test = pkgs.writeShellScriptBin "z-tmux-test" ''
            set -e
            export TMUX_PLUGIN_MANAGER_PATH="${pluginsDir}"
            exec ${pkgs.tmux}/bin/tmux -f ${tmuxConfNix} "$@"
          '';

          # Full test environment with tmuxp
          test-full = pkgs.writeShellScriptBin "z-tmux-test-full" ''
            set -e
            export PATH="${
              pkgs.lib.makeBinPath [
                pkgs.tmux
                pkgs.tmuxp
                pkgs.mosh
              ]
            }:$PATH"
            export TMUX_PLUGIN_MANAGER_PATH="${pluginsDir}"

            if [ "$1" = "session" ]; then
              ${pkgs.tmuxp}/bin/tmuxp load ${./tmux/sessions/remote-dev.yaml}
            else
              exec ${pkgs.tmux}/bin/tmux -f ${tmuxConfNix} "$@"
            fi
          '';
        }
      );
    };
}
