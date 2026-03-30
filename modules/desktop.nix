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

  # --- Audio & Video (PipeWire) ---
  # Enable rtkit for better real-time audio/video performance
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    # Enable wireplumber for device management (including webcams)
    wireplumber = {
      enable = true;

      # Disable libcamera monitor to avoid conflicts with v4l2 webcam access.
      # WirePlumber 0.5+ uses SPA-JSON config format (wireplumber.conf.d/),
      # NOT the old Lua main.lua.d/ format from WirePlumber 0.4.
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-disable-libcamera.conf" ''
          wireplumber.profiles = {
            main = {
              monitor.libcamera = disabled
            }
          }
        '')
      ];
    };
  };

  # --- GNOME Keyring & Security ---
  services.gnome.gnome-keyring.enable = true;

  # Enable keyring unlock at login (cosmic-greeter handles this)
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.cosmic-greeter.enableGnomeKeyring = true;

  # Essential packages for keyring management and webcam testing
  environment.systemPackages = with pkgs; [
    seahorse
    libsecret
    gcr
    v4l-utils # Webcam testing tools (v4l2-ctl, etc.)
    libcamera  # Camera support library with testing tools
  ];

  # Register gcr on D-Bus
  services.dbus.packages = [ pkgs.gcr ];

  # Portals
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-cosmic
      pkgs.xdg-desktop-portal-gtk
    ];
    # Portal backend configuration
    # IMPORTANT: The Camera portal is NOT implemented by gtk or cosmic backends.
    # It is handled by xdg-desktop-portal core via PipeWire.
    # Do NOT assign "Camera" to any backend, or webcam access from browsers will break.
    config.common = {
      default = "cosmic";
      "org.freedesktop.impl.portal.ScreenCast" = "cosmic";
      "org.freedesktop.impl.portal.Screenshot" = "cosmic";
      # GTK portal as fallback for file chooser, app chooser, etc.
      "org.freedesktop.impl.portal.FileChooser" = "gtk";
      "org.freedesktop.impl.portal.AppChooser" = "gtk";
    };
  };

  programs.dconf.enable = true;
}
