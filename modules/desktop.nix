{ config, pkgs, ... }:

{
  # --- Compositor (Hyprland nixosModule imported via flake) ---
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    # Keep XWayland for Electron/legacy apps (Discord, Slack screen-share).
    xwayland.enable = true;
  };

  programs.dconf.enable = true;

  # tty keymap (no X server)
  console.keyMap = "us";

  # --- Greeter ---
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # --- Bluetooth ---
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # --- Audio (PipeWire) ---
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    wireplumber = {
      enable = true;

      # WirePlumber 0.5+ SPA-JSON config; disable libcamera to avoid clashing
      # with v4l2 webcam access.
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

  # --- GNOME Keyring ---
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  environment.systemPackages = with pkgs; [
    seahorse
    libsecret
    gcr
    v4l-utils
    libcamera

    # Hyprland keybind targets
    grim
    slurp
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    pamixer
  ];

  services.dbus.packages = [ pkgs.gcr ];

  # --- Portals (Wayland) ---
  xdg.portal = {
    enable = true;
    # xdg-desktop-portal-hyprland is added automatically by programs.hyprland.enable.
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = "gtk";
    };
  };
}
