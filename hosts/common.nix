{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # --- 1. System & Boot ---
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;

      max-jobs = "auto";
      cores = 0;

      trusted-users = [ "root" ];

      keep-outputs = true;
      keep-derivations = true;

      # Hyprland Cachix (https://wiki.hypr.land/Nix/Cachix/) — the Hyprland
      # flake isn't built by Hydra, so without this every rebuild compiles
      # mesa/ffmpeg/Hyprland from source.
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
      ];
      trusted-substituters = [
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  # Kernel sysctls — generic, safe across host and VM
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "cake";
    "vm.swappiness" = 10;
    "fs.inotify.max_user_watches" = 524288;
  };

  # --- 2. Networking ---
  services.tailscale.enable = true;
  # NOTE: Do NOT enable networking.nftables here. It switches the firewall
  # backend to native nftables, which conflicts with Docker's iptables-nft
  # bridge/NAT rules and makes containers (and the host bridge) unreachable.
  # The host firewall is disabled, so trustedInterfaces/allowedUDPPorts would
  # be inert anyway; Tailscale works fine on the default (iptables) backend.
  networking.firewall.enable = false;

  # Optimization: don't block boot waiting for the network to come online
  # (helpful with VPNs like Tailscale).
  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;

  networking.networkmanager.enable = true;

  virtualisation.docker.enable = true;
  security.polkit.enable = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # --- 3. Locale ---
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };

  # --- 4. User & Packages ---
  users.users.co5mo = {
    isNormalUser = true;
    description = "co5mo";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "video"
      "input"
    ];
    shell = pkgs.zsh;
  };
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
  ];
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    htop

    pciutils
    usbutils

    netcat-gnu

    kind
  ];

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "overload(ctrl_vim, esc)";
        };

        # ctrl_vim modifier layer; inherits from 'Ctrl' modifier layer
        "ctrl_vim:C" = {
          space = "swap(vim_mode)";
        };

        # vim_mode modifier layer; also inherits from 'Ctrl' modifier layer
        "vim_mode:C" = {
          h = "left";
          j = "down";
          k = "up";
          l = "right";
          # forward word
          w = "C-right";
          # backward word
          b = "C-left";
        };
      };
    };
  };

  nixpkgs.config.allowUnfree = true;

  documentation = {
    man.cache.enable = true;
    dev.enable = true;
  };

  # NOTE: system.stateVersion is set per host (pluto / plutovm).
}
