{
  description = "Nixos config flake";

  inputs = {
    # Passiamo a stable ;)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager: per gestire la /home
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs-unstable";
    oh-my-tmux = {
      url = "github:gpakosz/.tmux";
      flake = false; # Non è un flake, ma un semplice repository
    };
    solaar = {
      url =
        "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz"; # For latest stable version
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    opencode.url = "github:GutMutCode/opencode-nix";
    nordvpn.url = "github:connerohnesorge/nordvpn-flake";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, solaar, sops-nix
    , opencode, nordvpn, ... }@inputs: {
      nixosConfigurations = {
        nixos = let
          system = "x86_64-linux";

          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        in nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          specialArgs = {
            inherit inputs;
            inherit pkgs-unstable;
          };
          modules = [
            ./configuration.nix

            solaar.nixosModules.default

            # Add opencode overlay
            {
              nixpkgs.overlays = [ opencode.overlays.default ];
            }

            # Modulo Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.backupFileExtension = "backup";

              home-manager.users.js = import ./home.nix;

              home-manager.extraSpecialArgs = {
                inherit inputs;
                inherit pkgs-unstable;
              };
            }
            inputs.nix-flatpak.nixosModules.nix-flatpak
          ];
        };
      };
      # NUOVA SEZIONE: Ambienti di sviluppo (Shells)
      devShells.x86_64-linux = let
        # Definisce il set di pacchetti 'pkgs' per l'architettura x86_64-linux
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      in {

        # 1. Definiamo la nostra shell "dev-tools" usando mkShell (la funzione standard)
        dev-tools = pkgs.mkShell {
          name = "dev-tools";

          # 2. Definiamo i pacchetti richiesti
          packages = with pkgs; [
            # Strumenti di sistema e diagnostica
            pciutils # Fornisce lspci
            util-linux # Fornisce lsblk (utile per i dischi)
            lm_sensors # Fornisce sensors

            # Strumenti per la Grafica (OpenGL/Vulkan)
            mesa-demos # Fornisce glxinfo
            vulkan-tools # Fornisce vulkaninfo
            glmark2
            vkmark

            # Strumenti per lo Stress Test
            stress-ng

            # Altri strumenti utili
            htop
            neofetch
          ];

          # 3. Variabili d'ambiente (opzionale, ma utile)
          shellHook = ''
            echo "Entering Persistent Nix Shell: dev-tools"
            echo "Available commands: lspci, glxinfo, vulkaninfo, stress-ng, glmark2, vkmark, htop."
          '';
        };
      };
    };
}
