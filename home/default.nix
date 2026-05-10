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

    # --- 1. PACCHETTI UTENTE ---
    packages =
      with pkgs;
      let
        # nixenv - Ephemeral Nix shell environment manager
        nixenv = pkgs.writeShellScriptBin "nixenv" (builtins.readFile ../scripts/nixenv);

      in
      [
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

        tree
        # App
        fastfetch # System info (modern neofetch replacement)
        inputs.zen-browser.packages."${pkgs.system}".default
        lecord # Installato a livello utente (non Flatpak)

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

        man-pages
        man-pages-posix

        nixenv # Ephemeral Nix shell environment manager

        # Rust toolchain manager (toolchains installed via `rustup` at runtime)
        rustup
      ];
    sessionVariables = {
      # Forza le app Electron a usare Wayland nativo (risparmio CPU/Batteria)
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };

    # sessionVariablesExtra removed — re-enable alongside the sops block
    # above when the age key is restored.

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
  home.file.".config/nixenv/envs/pwn.nix".source = ../scripts/nixenv-templates/pwn.nix;
  home.file.".config/nixenv/envs/web.nix".source = ../scripts/nixenv-templates/web.nix;
  home.file.".config/nixenv/envs/rev.nix".source = ../scripts/nixenv-templates/rev.nix;
  home.file.".config/nixenv/envs/crypto.nix".source = ../scripts/nixenv-templates/crypto.nix;

  home.file.".tmux.conf" = {
    source = "${inputs.oh-my-tmux}/.tmux.conf";
    # Rendi la copia gestita da Nix. Non modificarla direttamente.
  };

  home.file.".tmux.conf.local" = {
    source = "${inputs.oh-my-tmux}/.tmux.conf.local";
    # Copia questo file in modo che tu possa modificarlo localmente
    # (o Home Manager lo creerà se non esiste)
  };

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

        scrolling = {
          history = 10000;
        };

        font = {
          normal = {
            family = "MesloLGS Nerd Font";
          };
          size = 11.0;
          offset = {
            x = 0;
            y = 0;
          };
        };

        bell = {
          duration = 0;
        };
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
      };

      history = {
        size = 10000;
        path = "$HOME/.zsh_history";
      };

      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "sudo"
        ];
      };

      # Powerlevel10k theme (loaded after oh-my-zsh)
      initContent = ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        # npm global binaries (e.g. copilot)
        export PATH="$HOME/.npm-global/bin:$PATH"

        # GITLAB_TOKEN export removed — re-enable alongside the sops block.
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
  # network-manager-applet removed — it's an X11 tray applet that doesn't
  # render under Hyprland; DMS provides its own network widget.

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
      # Bound to hyprland-session.target (not graphical-session.target) because
      # native Hyprland (no UWSM) only reaches graphical-session.target *via*
      # hyprland-session.target — anchoring one rung lower avoids a cycle.
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "oneshot";
      # Propagate session environment to systemd/D-Bus user services.
      # PATH is critical: without it, xdg-desktop-portal can't resolve
      # Exec= lines in .desktop files → Flatpak "No Apps available" for OAuth.
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY PATH XDG_DATA_DIRS XDG_CURRENT_DESKTOP'";
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  # DankMaterialShell is installed system-wide via the NixOS module
  # (see modules/desktop.nix). Configs land in /etc/xdg/quickshell/dms.

  # Hyprland user config lives in ./hyprland (declarative attrset via
  # wayland.windowManager.hyprland.settings, split into hyprland.nix + binds.nix).

  # GTK theming — DMS's matugen integration writes color overrides; this just
  # turns the GTK module on so home-manager wires xdg paths correctly.
  gtk.enable = true;
}
