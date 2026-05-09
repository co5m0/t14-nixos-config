{ inputs, config, lib, pkgs, ... }: {
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    age.keyFile = "/home/co5mo/.config/sops/age/keys.txt";
    # Keep encrypted secrets out of the public repo; create this file locally.
    defaultSopsFile = ./secrets/secrets.yaml;

    secrets.github_token = { };
    secrets.gitlab_token = { };
  };
  home = {
    username = "co5mo";
    homeDirectory = "/home/co5mo";

    # --- 1. PACCHETTI UTENTE ---
    packages = with pkgs;
      let
        aider-pro = pkgs.writeShellScriptBin "aider-pro" ''
          TOKEN=$(cat ${config.sops.secrets.github_token.path})

          # Variabili base per l'auth
          export GITHUB_TOKEN="$TOKEN"
          export AIDER_GITHUB_COPILOT_API_KEY="$TOKEN"

          # --- MODEL DEFAULTS (balanced power/cost) ---
          # Default: cheaper + still strong for most coding tasks
          AIDER_MODEL="github_copilot/claude-sonnet-4.5"
          AIDER_EDITOR_MODEL="github_copilot/claude-haiku-4.5"

          # Build optional flags
          EXTRA_FLAGS=""

          # Opt-in "max power" when needed:
          #   AIDER_POWER=1 aider-pro ...
          if [ "''${AIDER_POWER:-0}" = "1" ]; then
            AIDER_MODEL="github_copilot/gpt-5.2"
            AIDER_EDITOR_MODEL="github_copilot/claude-haiku-4.5"
            echo "Mode: GitHub Copilot Business (MAX POWER)"
          else
            echo "Mode: GitHub Copilot Business (Balanced)"
          fi

          # Opt-in architect mode (expensive, two-stage planning):
          #   AIDER_ARCHITECT=1 aider-pro ...
          if [ "''${AIDER_ARCHITECT:-0}" = "1" ]; then
            EXTRA_FLAGS="$EXTRA_FLAGS --architect --map-refresh manual"
            echo "  + Architect mode enabled (expensive, manual map refresh)"
          fi

          # Opt-in watch-files mode (continuous monitoring):
          #   aider-pro --watch-files ...
          # Note: --watch-files is passed through "$@" if user specifies it

          # --- CONFIGURAZIONE EDITOR DI TESTO (Opzionale) ---
          AIDER_EDITOR="nvim"

          ${pkgs.aider-chat}/bin/aider \
            --model "$AIDER_MODEL" \
            --editor-model "$AIDER_EDITOR_MODEL" \
            --model-settings-file ~/.aider.model.settings.yml \
            --cache-prompts \
            --auto-lint \
            $EXTRA_FLAGS \
            "$@"
        '';

        # nixenv - Ephemeral Nix shell environment manager
        nixenv = pkgs.writeShellScriptBin "nixenv"
          (builtins.readFile ./scripts/nixenv);

      in [
        # Core
        tmux
        dnsutils
        wget
        curl
        unzip
        ripgrep
        fd
        wl-clipboard
        jq

        # System monitoring
        btop # Modern system monitor (better than htop)
        nvtopPackages.amd # GPU monitor (AMD-only build; avoids CUDA closure bloat)
        powertop # Power consumption analysis

        # Tool per la Shell (Aggiunti dal tuo .zshrc)
        eza # Per gli alias ls, ll, lt
        bat # Per le funzioni di preview

        sops
        nix-direnv
        nodejs_22
        (python3.withPackages (p: [ p.ipython ]))
        gh
        github-copilot-cli # Provides: github-copilot-cli, ghcs, ghce aliases
        glab # GitLab CLI

        tree
        # App
        fastfetch # System info (modern neofetch replacement)
        inputs.zen-browser.packages."${pkgs.system}".default
        discord # Installato a livello utente (non Flatpak)

        # --- FONT ---
        # Font di base per una buona copertura Unicode/Emoji
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji

        # Icone per barre di stato e applicazioni
        font-awesome

        # Nerd Fonts (Cruciali per P10K e Neovim)
        # Usa il namespace 'nerd-fonts' per installare solo quelli che ti servono
        nerd-fonts.jetbrains-mono # Ottimo per il coding
        nerd-fonts.fira-code # Altra ottima scelta con legature
        nerd-fonts.meslo-lg # Raccomandato ufficialmente da Powerlevel10k
        nerd-fonts.symbols-only # Se vuoi solo le icone

        # Packages per LazyVim
        statix
        nil
        nixfmt
        mailspring


        zed

        man-pages
        man-pages-posix

        aider-pro
        nixenv # Ephemeral Nix shell environment manager
        ctags # Utile per la repo map di Aider

        aider-chat
        ansible

        # Rust toolchain manager (toolchains installed via `rustup` at runtime)
        rustup
      ];
    sessionVariables = {
      # Forza le app Electron a usare Wayland nativo (risparmio CPU/Batteria)
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };

    # Session variables that need to read from sops secrets
    # Note: These are loaded at shell initialization, not at build time
    sessionVariablesExtra = ''
      # Expose GitHub token for OpenCode MCP servers (same token used by Aider)
      if [ -f "${config.sops.secrets.github_token.path}" ]; then
        export GITHUB_TOKEN="$(cat ${config.sops.secrets.github_token.path})"
      fi
    '';

    # rustup: add cargo and active toolchain binaries to PATH
    # npm global installs
    sessionPath = [
      "$HOME/.cargo/bin"
      "$HOME/.npm-global/bin"
    ];

    activation.installNpmGlobalPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.nodejs_22}/bin/npm install -g --prefix "$HOME/.npm-global" @github/copilot 2>&1 | tail -3
    '';
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "zen-beta.desktop" ];
      "x-scheme-handler/https" = [ "zen-beta.desktop" ];
      "text/html" = [ "zen-beta.desktop" ];
      "application/xhtml+xml" = [ "zen-beta.desktop" ];
    };
  };

  # nixenv environment templates
  home.file.".config/nixenv/envs/pwn.nix".source =
    ./scripts/nixenv-templates/pwn.nix;
  home.file.".config/nixenv/envs/web.nix".source =
    ./scripts/nixenv-templates/web.nix;
  home.file.".config/nixenv/envs/rev.nix".source =
    ./scripts/nixenv-templates/rev.nix;
  home.file.".config/nixenv/envs/crypto.nix".source =
    ./scripts/nixenv-templates/crypto.nix;

  home.file.".tmux.conf" = {
    source = "${inputs.oh-my-tmux}/.tmux.conf";
    # Rendi la copia gestita da Nix. Non modificarla direttamente.
  };

  home.file.".tmux.conf.local" = {
    source = "${inputs.oh-my-tmux}/.tmux.conf.local";
    # Copia questo file in modo che tu possa modificarlo localmente 
    # (o Home Manager lo creerà se non esiste)
  };

  # Configurazione persistente di Aider
  home.file.".aider.conf.yml".text = ''
    # --- UI & Aspetto ---
    dark-mode: true
    pretty: true
    stream: true

    # Reduced to 768 for better cost/benefit ratio (~25% savings vs 1024)
    # Sufficient for most projects while keeping context quality high
    map-tokens: 768

    # --- Cost Controls ---
    # Explicitly disable features that increase token usage
    auto-commits: false
    attribute-author: false
    attribute-committer: false
    attribute-commit-message-author: false
    attribute-commit-message-committer: false

    check-update: false
    show-model-warnings: false

    # --- Quality & Caching ---
    # Maximize cache hits - no keepalive pings waste tokens
    cache-keepalive-pings: 0

    # Only refresh map when explicitly needed (--map-refresh flag)
    # Default behavior refreshes on every file change = wasted tokens
    map-refresh: auto

    # Free quality improvements - run local checks before consuming tokens
    # Manual control to avoid surprise costs in scripts
    lint-cmd: "nix flake check 2>&1 || true"
    auto-lint: false

  '';
  home.file.".aider.model.settings.yml".text = ''
    # Apply these headers to ALL models automatically
    - name: aider/extra_params
      extra_params:
        extra_headers:
          Editor-Version: "vscode/1.96.2"
          Editor-Plugin-Version: "copilot/1.256.0"
          User-Agent: "GithubCopilot/1.256.0"
          Copilot-Integration-Id: "vscode-chat"
  '';

  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        addKeysToAgent = "yes";
        forwardAgent = false;
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
    };
    direnv = {
      enable = true;
      enableZshIntegration = true; # Hooks into your Zsh automatically
      nix-direnv.enable = true; # Better caching for Nix
    };

    thunderbird = {
      enable = true;
      profiles.co5mo = { isDefault = true; };
    };
    alacritty = {
      enable = true;
      settings = {
        window = {
          padding = {
            x = 0;
            y = 0;
          };
          opacity = 0.98;
        };

        scrolling = { history = 10000; };

        font = {
          normal = { family = "MesloLGS Nerd Font"; };
          size = 11.0;
          offset = {
            x = 0;
            y = 0;
          };
        };

        bell = { duration = 0; };
      };
    };

    git = {
      enable = true;
      package = pkgs.git.override { withLibsecret = true; };
      settings = {
        user.name = "co5mo";
        user.email = "mario@exein.io";
        core.editor = "nvim";
        credential.helper = "libsecret";
        init.defaultBranch = "main";
      };
    };
    zsh = {
      enable = true;
      enableCompletion = true;

      # Fast native plugins (better than Oh My Zsh alternatives)
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        cls = "clear";
        update = "sudo nixos-rebuild switch --flake ~/nixos-config#pluto";
        ls = "eza --icons";
        ll = "eza -al --icons";
        lt = "eza -a --tree --level=1 --icons";
        cd = "z";
        spotify = "flatpak run com.spotify.Client";
        firefox = "flatpak run org.mozilla.firefox";
        chromium = "flatpak run org.chromium.Chromium";

        # Aider workflow aliases
        ai = "aider-pro"; # Quick access, balanced mode
        aip = "AIDER_POWER=1 aider-pro"; # Power mode (GPT-5.2)
        aia = "AIDER_ARCHITECT=1 aider-pro"; # Architect mode only
        aipa =
          "AIDER_POWER=1 AIDER_ARCHITECT=1 aider-pro"; # Maximum power + architect
        aiw = "aider-pro --watch-files"; # Watch mode for live file monitoring
      };

      history = {
        size = 10000;
        path = "$HOME/.zsh_history";
      };

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "sudo" ];
      };

      # Powerlevel10k theme (loaded after oh-my-zsh)
      initContent = ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        # npm global binaries (e.g. copilot)
        export PATH="$HOME/.npm-global/bin:$PATH"

        # Export GitLab Token for glab and gitlab.nvim
        if [ -f "${config.sops.secrets.gitlab_token.path}" ]; then
          export GITLAB_TOKEN="$(cat ${config.sops.secrets.gitlab_token.path})"
        fi
      '';
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      withPython3 = false;
      withRuby = false;
    };

    vscode = {
      enable = true;
      profiles.default.extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
        yzhang.markdown-all-in-one
      ];
    };

    fzf.enable = true;
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
  # --- 3. SERVIZI ---
  services.ssh-agent.enable = true;
  services.network-manager-applet.enable = true;

  # services.gnome-keyring = {
  #   enable = true;
  #   components = [ "pkcs11" "secrets" "ssh" ];
  # };

  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
  };

  # --- 4. STATO ---
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

  programs.gh = {
    enable = true;
    # gh-copilot extension was removed from nixpkgs; use the standalone
    # github-copilot-cli (already in home.packages above) instead.
  };

  systemd.user.services.fix-dbus-environment = {
    Unit = {
      Description = "Fix DBus environment variables for Wayland session";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      # Propagate session environment to systemd/D-Bus user services.
      # PATH is critical: without it, xdg-desktop-portal can't resolve
      # Exec= lines in .desktop files → Flatpak "No Apps available" for OAuth.
      ExecStart =
        "${pkgs.bash}/bin/bash -c '${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY PATH XDG_DATA_DIRS XDG_CURRENT_DESKTOP'";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  # --- DankMaterialShell (Hyprland shell: bar, launcher, lock, idle, notif, control center, polkit agent) ---
  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    # All feature toggles default to true:
    #   enableSystemMonitoring  (dgop)
    #   enableVPN               (NetworkManager + glib bindings)
    #   enableDynamicTheming    (matugen — colors GTK/Qt/terminal from wallpaper)
    #   enableAudioWavelength   (cava)
    #   enableCalendarEvents    (khal)
    #   enableClipboardPaste    (wtype)
  };

  # --- Hyprland (compositor config) ---
  # System-level enable lives in modules/desktop.nix; this is the user config
  # consumed by `Hyprland` when launched from greetd.
  #
  # Kept deliberately minimal so the v0.54 strict config parser can't trip on
  # an option whose type tightened. Layer features back in once the VM boots.
  xdg.configFile."hypr/hyprland.conf".text = ''
    monitor=,preferred,auto,1

    $mod = SUPER

    input {
      kb_layout = us
      kb_variant = altgr-intl
    }

    general {
      gaps_in = 4
      gaps_out = 8
      border_size = 2
      layout = dwindle
    }

    decoration {
      rounding = 8
    }

    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
    }

    # Core
    bind = $mod, Return, exec, alacritty
    bind = $mod, Q, killactive
    bind = $mod SHIFT, E, exit

    # DMS shell
    bind = $mod, Space, exec, dms ipc call spotlight toggle
    bind = $mod, L,     exec, dms ipc call lock lock

    # Window movement
    bind = $mod, left,  movefocus, l
    bind = $mod, right, movefocus, r
    bind = $mod, up,    movefocus, u
    bind = $mod, down,  movefocus, d

    # Workspaces 1-9
    bind = $mod, 1, workspace, 1
    bind = $mod, 2, workspace, 2
    bind = $mod, 3, workspace, 3
    bind = $mod, 4, workspace, 4
    bind = $mod, 5, workspace, 5
    bind = $mod, 6, workspace, 6
    bind = $mod, 7, workspace, 7
    bind = $mod, 8, workspace, 8
    bind = $mod, 9, workspace, 9

    bindm = $mod, mouse:272, movewindow
    bindm = $mod, mouse:273, resizewindow
  '';

  # GTK theming — DMS's matugen integration writes color overrides; this just
  # turns the GTK module on so home-manager wires xdg paths correctly.
  gtk.enable = true;
}
