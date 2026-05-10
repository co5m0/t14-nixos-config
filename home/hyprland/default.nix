{ ... }:
{
  imports = [ ./binds.nix ];

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # Multi-monitor setup ported verbatim from ~/.config/hypr/monitors.conf.
      # Inactive monitors are silently ignored when not connected.
      env = [
        "GDK_SCALE,2"
      ];

      monitor = [
        "eDP-1, 2880x1800@120.00Hz, auto-left, 1.6"
        "DP-9,  1920x1080@144Hz,    auto,      auto"
        "DP-2,  1920x1080,          auto-right, auto"
      ];

      # Input — kb_variant=mac, Compose on Caps Lock, natural scroll, two-finger
      # right-click, slower trackpad scrolling. Ported from ~/.config/hypr/input.conf.
      input = {
        kb_layout = "us";
        kb_variant = "mac";
        kb_options = "compose:caps";
        repeat_rate = 40;
        repeat_delay = 600;
        numlock_by_default = true;
        touchpad = {
          natural_scroll = true;
          clickfinger_behavior = true;
          scroll_factor = 0.4;
        };
      };

      # Three-finger horizontal swipe → workspace
      gesture = [ "3, horizontal, workspace" ];

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
      # and hyprpolkitagent all activate. Also autostart vicinae --server
      # (legacy launcher; kept running even though Super+Space → DMS).
      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user start hyprland-session.target"
        "vicinae server"
      ];
    };
  };
}
