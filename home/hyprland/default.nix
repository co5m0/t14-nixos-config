{ ... }:
{
  imports = [ ./binds.nix ];

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      monitor = [ ",preferred,auto,1" ];

      input = {
        kb_layout = "us";
        kb_variant = "altgr-intl";
      };

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      # Without UWSM, Hyprland is responsible for propagating session env to
      # the systemd user manager and starting hyprland-session.target — which
      # in turn binds graphical-session.target so DMS, fix-dbus-environment,
      # and hyprpolkitagent all activate. HM's systemd.enable=true (default)
      # already wires this; the explicit lines below are belt-and-suspenders.
      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user start hyprland-session.target"
      ];
    };
  };
}
