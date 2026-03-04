{ config, pkgs, ... }:

{
  # Keyboard layout (applies to both X11 and Wayland)
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };
  console.useXkbConfig = true; # Use same layout in console
  # --- BLUETOOTH FIX ---
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # --- COSMIC & Display Manager ---
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # --- GNOME Keyring & Security ---
  services.gnome.gnome-keyring.enable = true;

  # Enable keyring unlock at login (cosmic-greeter handles this)
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.cosmic-greeter.enableGnomeKeyring = true;

  # Essential packages for keyring management
  environment.systemPackages = with pkgs; [ seahorse libsecret gcr ];

  # Register gcr on D-Bus
  services.dbus.packages = [ pkgs.gcr ];

  # Portals
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];
    config.common.default = "*";
  };

  programs.dconf.enable = true;
}
