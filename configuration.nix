{ config, pkgs, pkgs-unstable, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/amd-optimization.nix
    ./modules/desktop.nix
    ./modules/flatpak.nix
  ];

  # --- 1. System & Boot ---
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;

      # Performance: Use all available cores for building
      max-jobs = "auto";
      cores = 0; # 0 = use all available cores

      # Safer public default: only root is trusted for privileged Nix operations.
      trusted-users = [ "root" ];

      # Keep build dependencies for faster rebuilds
      keep-outputs = true;
      keep-derivations = true;
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  boot = {
    # Using 6.18.2 with Arch Wiki workarounds for AMD Strix Point (Lenovo T14 Gen 6)
    # Arch Wiki (P14s Gen 6) confirms 6.17+ needed for WiFi/sleep support
    # Testing aggressive workarounds to address MES buffer saturation issues
    # See: https://wiki.archlinux.org/title/Lenovo_ThinkPad_P14s_(AMD)_Gen_6
    kernelPackages =
      pkgs.linuxPackages_latest; # 6.18.2 - with aggressive GPU workarounds
    # kernelPackages = pkgs.linuxPackages_6_12; # Fallback: LTS if 6.18 still unstable

    kernelParams = [
      # USB: mitigate xHCI refusing D0->D3hot / flaky suspend behavior
      "usbcore.autosuspend=-1"
      # Bluetooth: reduce common controller quirks/noise on some chipsets
      "btusb.enable_autosuspend=n"
    ];

    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit =
          10; # Keep only last 10 generations (prevents /boot from filling)
      };
      timeout = 3; # Boot menu timeout in seconds (default is 5)
      efi.canTouchEfiVariables = true;
    };

    # Kernel parameters for performance
    kernel.sysctl = {
      # Network performance (useful for fuzzing/CTF work)
      "net.core.default_qdisc" = "cake";

      # Virtual memory optimization
      "vm.swappiness" = 10; # Prefer RAM over swap

      # File system performance
      "fs.inotify.max_user_watches" = 524288; # For development tools
    };
  };

  # --- 2. Networking & Services ---
  networking.hostName = "js-laptop";
  networking.networkmanager.enable = true;

  services = {
    fprintd.enable = true;
    fstrim.enable = true;
    fwupd.enable = true;

    netbird = {
      enable = true;
      package = pkgs-unstable.netbird;
    };

  };

  virtualisation.docker.enable = true;
  security.polkit.enable = true;

  # Zram: Compressed RAM-based swap (better than disk swap)
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # Fast compression
    memoryPercent = 50; # Use up to 50% of RAM for compressed swap
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
  users.users.js = {
    isNormalUser = true;
    description = "js";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
  };
  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc.lib zlib ];
  programs.zsh.enable = true;

  # System-level packages (essential system tools only)
  # User packages should go in home.nix for better isolation
  environment.systemPackages = with pkgs; [
    vim # Essential editor for system recovery
    git # Required for flake operations
    htop # System monitoring (needed for multi-user systems)

    # Hardware inspection tools (useful for sysadmin/security work)
    pciutils # lspci - PCI device inspection
    usbutils # lsusb - USB device inspection

    # Network tools
    netcat-gnu

    # Note: Removed duplicates that are in home.nix or desktop.nix:
    # - wget (in home.nix)
    # - seahorse (in desktop.nix)
    # - networkmanagerapplet (user-specific, moved to home.nix)
    # - xdg-utils (included by desktop environment)
    # - vulkan-loader (moved to hardware.graphics.extraPackages)
  ];

  nixpkgs.config.allowUnfree = true;

  # Documentation
  documentation = {
    man.generateCaches = true; # Faster man page searches
    dev.enable = true; # Development documentation
  };
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
