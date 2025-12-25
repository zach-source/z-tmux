{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.z-tmux;

  # TPM (Tmux Plugin Manager)
  tpm = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tpm";
    rev = "v3.1.0";
    sha256 = "sha256-CeI9Wq6tHqV68woE11lIY4cLoNY8XWyXyMHTDmFKJKI=";
  };

  # tmux-which-key plugin
  tmuxWhichKey = pkgs.fetchFromGitHub {
    owner = "alexwforsythe";
    repo = "tmux-which-key";
    rev = "main";
    sha256 = "sha256-Dr4G8F5NtrZNlkGkBJ1mpvBAsW7+Rk9YlFkHl8KJiIs=";
  };
in
{
  options.z-tmux = {
    enable = lib.mkEnableOption "z-tmux configuration";

    prefix = lib.mkOption {
      type = lib.types.str;
      default = "C-a";
      description = "Tmux prefix key";
    };

    shell = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.zsh}/bin/zsh";
      description = "Default shell for tmux";
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
      description = "Continuum save interval in minutes";
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
      description = "Extra tmux configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install packages
    home.packages =
      with pkgs;
      [
        tmux
        gitmux # Git status in tmux
      ]
      ++ lib.optional cfg.enableMosh mosh
      ++ lib.optional cfg.enableTmuxp tmuxp;

    # Create TPM directory structure
    home.file.".tmux/plugins/tpm".source = tpm;
    home.file.".tmux/plugins/tmux-which-key".source = tmuxWhichKey;

    # Create resurrect directory
    home.file.".tmux/resurrect/.keep".text = "";

    # tmuxp sessions directory
    xdg.configFile."tmuxp/remote-dev.yaml".text = builtins.readFile ../tmux/sessions/remote-dev.yaml;

    # which-key configuration
    xdg.configFile."tmux/plugins/tmux-which-key/config.yaml".text =
      builtins.readFile ../tmux/which-key.yaml;

    # Main tmux configuration
    programs.tmux = {
      enable = true;
      terminal = "tmux-256color";
      shell = cfg.shell;
      prefix = cfg.prefix;
      keyMode = "vi";
      mouse = true;
      historyLimit = 50000;
      baseIndex = 1;
      escapeTime = 0;
      clock24 = true;

      plugins = with pkgs.tmuxPlugins; [
        {
          plugin = catppuccin;
          extraConfig = ''
            # Catppuccin configuration
            set -g @catppuccin_flavor "${cfg.catppuccinFlavor}"
            set -g @catppuccin_status_background "default"

            # Window styling
            set -g @catppuccin_window_status_style "rounded"
            set -g @catppuccin_window_number_position "right"
            set -g @catppuccin_window_default_fill "number"
            set -g @catppuccin_window_default_text "#W"
            set -g @catppuccin_window_current_fill "number"
            set -g @catppuccin_window_current_text "#W"

            # Status bar position
            set -g status-position top
            set -g status-interval 5

            # Status modules
            set -g @catppuccin_status_left_separator ""
            set -g @catppuccin_status_right_separator ""
            set -g @catppuccin_status_connect_separator "no"

            set -g status-left "#{E:@catppuccin_status_session}"
            set -g status-right "#{E:@catppuccin_status_directory}"
          '';
        }
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-dir '~/.tmux/resurrect'
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-strategy-nvim 'session'

            # Disable SSH/Mosh replay to prevent broken remote sessions
            set -g @resurrect-processes 'false'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-save-interval '${toString cfg.saveInterval}'
            set -g @continuum-restore 'on'
          '';
        }
        prefix-highlight
        yank
        sensible
      ];

      extraConfig = ''
        # ══════════════════════════════════════════════════════════════════════
        # Core Settings
        # ══════════════════════════════════════════════════════════════════════

        # True color support
        set -ag terminal-overrides ",xterm-256color:RGB"
        set -as terminal-features ",xterm-256color:RGB"

        # Focus events for vim
        set -g focus-events on

        # Pane numbering starts at 1
        setw -g pane-base-index 1

        # Renumber windows when one is closed
        set -g renumber-windows on

        # Don't rename windows automatically
        set -g allow-rename off

        # Activity monitoring
        setw -g monitor-activity on
        set -g visual-activity off

        # ══════════════════════════════════════════════════════════════════════
        # Key Bindings
        # ══════════════════════════════════════════════════════════════════════

        # Reload config
        bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

        # Split panes with | and -
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"

        # New window in current path
        bind c new-window -c "#{pane_current_path}"

        # Vim-style pane navigation
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Vim-style pane resizing
        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        # Alt + arrow for pane navigation (no prefix)
        bind -n M-Left select-pane -L
        bind -n M-Right select-pane -R
        bind -n M-Up select-pane -U
        bind -n M-Down select-pane -D

        # Shift + arrow to switch windows (no prefix)
        bind -n S-Left previous-window
        bind -n S-Right next-window

        # Quick window selection
        bind -r C-h select-window -t :-
        bind -r C-l select-window -t :+

        # Popup terminal
        bind p display-popup -E -w 80% -h 80% -d "#{pane_current_path}"

        # Synchronize panes toggle
        bind S setw synchronize-panes

        # Toggle status bar
        bind b set -g status

        # Clear history
        bind C-k clear-history

        # ══════════════════════════════════════════════════════════════════════
        # Copy Mode (Vi-style)
        # ══════════════════════════════════════════════════════════════════════

        bind Enter copy-mode
        bind -T copy-mode-vi v send -X begin-selection
        bind -T copy-mode-vi y send -X copy-selection-and-cancel
        bind -T copy-mode-vi Escape send -X cancel

        # Mouse selection copies to clipboard
        bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-selection-and-cancel

        # ══════════════════════════════════════════════════════════════════════
        # Session Management
        # ══════════════════════════════════════════════════════════════════════

        # Session switcher
        bind s choose-tree -sZ

        # Kill session
        bind X confirm-before -p "Kill session #S? (y/n)" kill-session

        # ══════════════════════════════════════════════════════════════════════
        # Which-Key Integration
        # ══════════════════════════════════════════════════════════════════════

        # Load which-key plugin
        run-shell ~/.tmux/plugins/tmux-which-key/plugin.sh.tmux

        # ══════════════════════════════════════════════════════════════════════
        # TPM (must be last)
        # ══════════════════════════════════════════════════════════════════════

        run '~/.tmux/plugins/tpm/tpm'

        # ══════════════════════════════════════════════════════════════════════
        # Extra Configuration
        # ══════════════════════════════════════════════════════════════════════

        ${cfg.extraConfig}
      '';
    };
  };
}
