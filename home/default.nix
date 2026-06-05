{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./hyprland ];

  # sops disabled — re-enable once the age key is in place at
  # /home/co5mo/.config/sops/age/keys.txt and uncomment all `config.sops.*`
  # references throughout this file.
  # imports = [ inputs.sops-nix.homeManagerModules.sops ];
  #
  # sops = {
  #   age.keyFile = "/home/co5mo/.config/sops/age/keys.txt";
  #   defaultSopsFile = ./secrets/secrets.yaml;
  #   secrets.github_token = { };
  #   secrets.gitlab_token = { };
  # };

  home = {
    username = "co5mo";
    homeDirectory = "/home/co5mo";

    packages = with pkgs; [
      # --- Core CLI ---
      tmux
      dnsutils
      wget
      curl
      unzip
      ripgrep
      fd
      wl-clipboard
      jq
      yq
      tree
      delta
      nnn
      yazi
      gcc

      # --- System monitoring ---
      btop
      nvtopPackages.amd
      powertop
      fastfetch

      # --- Shell helpers ---
      eza
      bat

      # --- Languages / toolchains ---
      nodejs_22
      corepack_24
      typescript
      go
      gopls
      rustup
      uv
      lua-language-server
      yaml-language-server
      (python3.withPackages (p: [ p.ipython ]))

      # --- Nix tooling ---
      sops
      nil
      nixfmt
      statix

      # --- Cloud / infra ---
      awscli2
      aws-vault
      ssm-session-manager-plugin
      pulumi-bin

      # --- Kubernetes ---
      kubectl
      k9s
      kind

      # --- TUI dev ---
      gh
      lazygit
      lazydocker
      lazysql

      # -- Hypr ---
      hyprshot

      # --- LLM CLIs ---
      # inputs.llm-agents.packages.${pkgs.system}.pi
      inputs.llm-agents.packages.${pkgs.system}.claude-code
      inputs.llm-agents.packages.${pkgs.system}.codex
      inputs.llm-agents.packages.${pkgs.system}.antigravity
      # inputs.llm-agents.packages.${pkgs.system}.omp

      # --- Dev Tools ---
      inputs.dagger.packages.${pkgs.system}.dagger
      inputs.vegadiff.packages.${pkgs.system}.vegadiff

      # --- Editor ---
      # Bare neovim (no HM module): init.lua + lazy.nvim manage plugins at
      # runtime. See xdg.configFile."nvim/*" below.
      neovim

      # --- Apps ---
      inputs.zen-browser.packages.${pkgs.system}.default
      legcord
      mailspring
      rtk
      fence

      # --- Fonts ---
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.meslo-lg
      nerd-fonts.symbols-only

      # --- Manpages ---
      man-pages
      man-pages-posix
    ];

    sessionVariables = {
      # Wayland / Electron
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";

      # Locale + editors (ported from ~/.nix/home-manager.nix)
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      EDITOR = "nvim";
      PAGER = "less -FirSwX";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    };

    # cargo + npm-global + flutter on PATH
    sessionPath = [
      "$HOME/.cargo/bin"
      "$HOME/.npm-global/bin"
      "$HOME/.local/share/flutter/bin"
    ];

    activation.installNpmGlobalPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.nodejs_22}/bin/npm install -g --prefix "$HOME/.npm-global" @github/copilot 2>&1 | tail -3
    '';

    file = {
      ".tmux.conf".source = "${inputs.oh-my-tmux}/.tmux.conf";
      ".tmux.conf.local".source = ./tmux/conf.local;
      ".config/xdg-terminals.list".source = ./xdg-terminals.list;
      ".npmrc".text = ''
        prefix=${config.home.homeDirectory}/.npm-global
        cache=${config.home.homeDirectory}/.cache/npm
      '';
    };

    stateVersion = "25.11";
  };

  # Default browser. Zen ships as zen-beta.desktop (Exec=zen-beta); register it
  # as the handler for web schemes/HTML so links open in Zen everywhere.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "zen-beta.desktop";
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "x-scheme-handler/about" = "zen-beta.desktop";
      "x-scheme-handler/unknown" = "zen-beta.desktop";
    };
  };

  # --- Raw config files ported from ~/.config ---
  xdg.configFile = {
    "btop/btop.conf".source = ./btop/btop.conf;
    "lazygit/config.yml".source = ./lazygit/config.yml;
    "yazi/yazi.toml".source = ./yazi/yazi.toml;
    "gh-dash/config.yml".source = ./gh-dash/config.yml;
    "fontconfig/fonts.conf".source = ./fontconfig/fonts.conf;

    # Recursive: ghostty config + shaders subdir
    "ghostty" = {
      source = ./ghostty;
      recursive = true;
    };

    # Neovim — recursive deploy. lazy.nvim bootstraps from init.lua at first
    # launch and pulls plugins per lazy-lock.json. .neoconf.json is the
    # neoconf.nvim per-project LSP config schema. Conductor markdown files
    # are user notes (kept alongside config).
    "nvim" = {
      source = ./nvim;
      recursive = true;
    };

    # Hyprland clamshell-mode script (referenced by bindl in hyprland binds)
    "hypr/clamshell_mode.sh" = {
      source = ./hypr/clamshell_mode.sh;
      executable = true;
    };
  };

  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      # matchBlocks."*" = {
      #   addKeysToAgent = "yes";
      #   forwardAgent = false;
      #   compression = false;
      #   serverAliveInterval = 0;
      #   serverAliveCountMax = 3;
      #   hashKnownHosts = false;
      #   userKnownHostsFile = "~/.ssh/known_hosts";
      #   controlMaster = "no";
      #   controlPath = "~/.ssh/master-%r@%n:%p";
      #   controlPersist = "no";
      # };
    };

    git = {
      enable = true;
      package = pkgs.git.override { withLibsecret = true; };

      settings = {
        alias = {
          co = "checkout";
          br = "branch";
          ci = "commit";
          st = "status";
        };

        user.name = "co5mo";
        user.email = "marioconsalvo1@gmail.com";
        core.editor = "nvim";
        credential.helper = "libsecret";
        init.defaultBranch = "master";

        pull.rebase = true;
        push.autoSetupRemote = true;

        merge.tool = "vegadiff";
        mergetool.vegadiff = {
          cmd = ''vegadiff "$BASE" "$LOCAL" "$REMOTE" "$MERGED"'';
          trustExitCode = true;
        };

        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
        };
        commit.verbose = true;
        column.ui = "auto";
        branch.sort = "-committerdate";
        tag.sort = "-version:refname";
        rerere = {
          enabled = true;
          autoupdate = true;
        };
      };
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      dotDir = "${config.xdg.configHome}/zsh";

      shellAliases = {
        # Aliases ported from ~/.nix/home-manager.nix
        ll = "ls -l";
        la = "ls -a";
        switch = "sudo nixos-rebuild switch --flake ~/.nix#pluto";
        update = "sudo nix flake update --flake ~/.nix";
        rless = "less -r";
        vim = "nvim";
        vi = "nvim";
        tf = "terraform";
        k = "kubectl";
        lgit = "lazygit";
        lsql = "lazysql";
        ldocker = "lazydocker";
        grep = "rg";
        cls = "clear";
      };

      sessionVariables = {
        EDITOR = "nvim";
        TERMINFO = "$HOME/.terminfo";
        TERM = "xterm-256color";
        NNN_FCOLORS = "D4DEB778E79F9F67D2E5E5D2";

        # npm global installs must not target /nix/store
        NPM_CONFIG_PREFIX = "$HOME/.npm-global";
        NPM_CONFIG_CACHE = "$HOME/.cache/npm";
      };

      history = {
        size = 10000;
        path = "$HOME/.zsh_history";
      };

      oh-my-zsh = {
        enable = true;
        theme = "agnoster";
        plugins = [
          "git"
          "docker"
          "aws"
          "extract"
          "terraform"
          "gh"
          "vi-mode"
          "fzf"
          "kubectl"
        ];
        extraConfig = ''
          PROMPT="$PROMPT\$(vi_mode_prompt_info)"
          RPROMPT="\$(vi_mode_prompt_info)$RPROMPT"
        '';
      };

      initContent = lib.mkMerge [
        (lib.mkBefore ''
          typeset -U path PATH
          path=("$HOME/.local/share/flutter/bin" $path)
        '')
        ''
          if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
            tmux attach-session -t default || tmux new-session -s default
          fi

          DEFAULT_USER=$USER
          VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
          MODE_INDICATOR="%F{white}N%f"
          INSERT_MODE_INDICATOR="%F{yellow}I%f"
          VI_MODE_SET_CURSOR=true
          prompt_context(){}
          prompt_dir(){
              prompt_segment cyan $CURRENT_FG '%~'
          }
          ch(){
              curl https://raw.githubusercontent.com/cheat/cheatsheets/refs/heads/master/$1
          }
          function n() {
              local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
              command yazi "$@" --cwd-file="$tmp"
              IFS= read -r -d "" cwd < "$tmp"
              [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
              rm -f -- "$tmp"
          }

          # npm global binaries
          export PATH="$HOME/.npm-global/bin:$PATH"
        ''
      ];
    };

    fzf.enable = true;

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    home-manager.enable = true;
  };

  services = {
    ssh-agent.enable = true;
  };

  # Propagate session env into systemd --user (flatpak portals, etc.)
  # Anchored to hyprland-session.target since native Hyprland reaches
  # graphical-session.target via the former.
  systemd.user.services.fix-dbus-environment = {
    Unit = {
      Description = "Fix DBus environment variables for Wayland session";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY PATH XDG_DATA_DIRS XDG_CURRENT_DESKTOP'";
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  # GTK module on so HM wires xdg paths correctly; DMS matugen writes the
  # actual color overrides.
  gtk.enable = true;

  # DankMaterialShell is installed system-wide via the NixOS module
  # (see modules/desktop.nix). Configs land in /etc/xdg/quickshell/dms.

  # Hyprland user config lives in ./hyprland (declarative attrset via
  # wayland.windowManager.hyprland.settings, split into hyprland.nix + binds.nix).
}
