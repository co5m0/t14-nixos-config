{
  description = "Nixos config flake — pluto (laptop) + plutovm (manual-install VM)";

  # Hyprland binary cache — applies during `nix build`/`nixos-rebuild` even
  # before the system-level substituters in hosts/common.nix have been
  # activated (matters on the very first install).
  # Per the wiki (https://wiki.hypr.land/Nix/Cachix/) we deliberately do NOT
  # override hyprland's nixpkgs input — that would defeat the cache.
  nixConfig = {
    extra-substituters = [ "https://hyprland.cachix.org" ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    # Single channel: nixos-unstable.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # home-manager master tracks unstable.
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Compositor + shell
    # Pinned to a release tag for stable cache hits — `main` would change
    # between flake updates and force fresh compiles each time.
    hyprland.url = "github:hyprwm/Hyprland/v0.55.0";

    # Pinned to /stable per upstream NixOS-flake docs:
    # https://danklinux.com/docs/dankmaterialshell/nixos-flake
    dms.url = "github:AvengeMedia/DankMaterialShell/stable";
    dms.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    oh-my-tmux = {
      url = "github:gpakosz/.tmux";
      flake = false;
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, hyprland, dms, ... }@inputs:
    let
      system = "x86_64-linux";

      # Module set shared across both NixOS hosts.
      # Per-host entry point (./hosts/{pluto,plutovm}.nix) is added on top.
      sharedModules = [
        ./modules/desktop.nix
        ./modules/flatpak.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.co5mo = import ./home;
          home-manager.extraSpecialArgs = {
            inherit inputs;
          };
        }

        inputs.nix-flatpak.nixosModules.nix-flatpak
        hyprland.nixosModules.default

        # System-wide DankMaterialShell — places quickshell configs in
        # /etc/xdg/quickshell/dms (per upstream docs).
        dms.nixosModules.dank-material-shell
      ];

      mkHost = hostModule: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = sharedModules ++ [ hostModule ];
      };
    in {
      # `pluto`    — real T14 laptop install (uses ./hardware-configuration.nix).
      # `plutovm`  — manual-install VM. User installs NixOS by hand, clones the
      #              repo inside, copies hardware-configuration.nix into
      #              hosts/plutovm-hardware.nix, then `nixos-rebuild switch`.
      nixosConfigurations = {
        pluto = mkHost ./hosts/pluto.nix;
        plutovm = mkHost ./hosts/plutovm.nix;
      };

      devShells.${system} = let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        dev-tools = pkgs.mkShell {
          name = "dev-tools";
          packages = with pkgs; [
            pciutils
            util-linux
            lm_sensors
            mesa-demos
            vulkan-tools
            glmark2
            vkmark
            stress-ng
            htop
            fastfetch
          ];
          shellHook = ''
            echo "Entering Persistent Nix Shell: dev-tools"
            echo "Available commands: lspci, glxinfo, vulkaninfo, stress-ng, glmark2, vkmark, htop."
          '';
        };
      };
    };
}
