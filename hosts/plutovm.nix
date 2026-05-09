{ config, lib, pkgs, ... }:

{
  imports = [
    ./common.nix
    # Per-VM hardware config. Absolute paths break flake pure-eval, so the
    # user copies their generated file in before first rebuild:
    #   sudo cp /etc/nixos/hardware-configuration.nix hosts/plutovm-hardware.nix
    # The repo .gitignores it so each VM keeps its own.
    ./plutovm-hardware.nix
  ];

  networking.hostName = "plutovm";

  # UEFI boot — the manual NixOS install will set up an ESP at /boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- VM guest niceties ---
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # SSH for headless poking from the host.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  # Auto-login co5mo straight into Hyprland — no password challenge in VM.
  services.greetd.settings.default_session.command = lib.mkForce
    "${pkgs.tuigreet}/bin/tuigreet --time --remember --user-menu --cmd Hyprland";

  # Initial password (used at first activation; change with `passwd` after first login).
  users.users.co5mo.initialPassword = "plutovm";

  system.stateVersion = "25.11";
}
