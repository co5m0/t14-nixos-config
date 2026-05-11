{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./common.nix
    ../hardware-configuration.nix
    ../modules/amd-optimization.nix
    ../modules/amd-suspend-fix.nix
  ];

  networking.hostName = "pluto";

  # --- Boot (T14 Strix Point specifics) ---
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "mem_sleep_default=s2idle"
    "btusb.enable_autosuspend=n"
  ];
  boot.kernelModules = [ "sch_cake" ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.timeout = 3;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Laptop services ---
  services.fprintd.enable = true;
  services.fstrim.enable = true;
  services.fwupd.enable = true;

  system.stateVersion = "25.11";
}
