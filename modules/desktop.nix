{ config, pkgs, ... }:

{
  # --- Compositor (Hyprland nixosModule imported via flake) ---
  # Native session launch (no UWSM): Hyprland is started directly from
  # `hyprland.desktop`. Hyprland's exec-once handshake (see
  # ./home/hyprland/default.nix) propagates session env into systemd --user
  # and activates `hyprland-session.target`, which in turn binds
  # `graphical-session.target` so DMS and other user services start.
  programs.hyprland = {
    enable = true;
    # Keep XWayland for Electron/legacy apps (Discord, Slack screen-share).
    xwayland.enable = true;
  };

  services.displayManager.defaultSession = "hyprland";

  # --- DankMaterialShell (system-wide install per upstream docs) ---
  # Provides bar, launcher, lock, idle, notifications, control center,
  # polkit agent. Quickshell configs live at /etc/xdg/quickshell/dms.
  # Feature toggles (enableSystemMonitoring, enableVPN, enableDynamicTheming,
  # enableAudioWavelength, enableCalendarEvents, enableClipboardPaste) all
  # default to true.
  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
  };

  programs.dconf.enable = true;

  # tty keymap (no X server)
  console.keyMap = "us";

  # --- Greeter ---
  # tuigreet reads .desktop files from XDG_DATA_DIRS and execs the chosen
  # file's Exec= line. `--remember-session` makes the first pick stick on
  # subsequent logins.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session";
        user = "greeter";
      };
    };
  };

  # --- Polkit auth agent ---
  # Anchored to hyprland-session.target (same rationale as
  # fix-dbus-environment in home.nix): under a native Hyprland launch,
  # graphical-session.target is reached transitively.
  systemd.user.services.hyprpolkitagent = {
    description = "Hyprpolkitagent — polkit authentication agent";
    wantedBy = [ "hyprland-session.target" ];
    wants    = [ "hyprland-session.target" ];
    after    = [ "hyprland-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # --- Power (UPower) ---
  # DMS battery widget reads state via UPower over DBus.
  services.upower.enable = true;

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

    # Default terminal (referenced by hyprland Super+Return)
    ghostty

    # Kubernetes helper (system-wide so root can use it too)
    kubernetes-helm
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
