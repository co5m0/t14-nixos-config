{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      # --- Core ---
      "SUPER, Return,    exec, ghostty"
      "SUPER ALT, Return, exec, ghostty -e tmux new"
      "SUPER, Q,         killactive"
      "SUPER SHIFT, E,   exit"

      # --- DMS shell (Super+Space owned by DMS spotlight; vicinae runs in
      # background via exec-once but isn't keybound) ---
      "SUPER, Space,     exec, dms ipc call spotlight toggle"
      "SUPER, L,         exec, dms ipc call lock lock"

      # --- App launchers (translated from Omarchy helpers; flatpak/nix paths) ---
      "SUPER SHIFT, Return, exec, zen-browser"
      "SUPER SHIFT, B,      exec, zen-browser"
      "SUPER SHIFT ALT, B,  exec, zen-browser --private"
      "SUPER SHIFT, F,      exec, nautilus --new-window"
      "SUPER SHIFT, M,      exec, flatpak run com.spotify.Client"
      "SUPER SHIFT, N,      exec, ghostty -e nvim"
      "SUPER SHIFT, T,      exec, ghostty -e btop"
      "SUPER SHIFT, D,      exec, ghostty -e lazydocker"
      "SUPER SHIFT, O,      exec, obsidian --enable-wayland-ime"
      "SUPER SHIFT, W,      exec, typora --enable-wayland-ime"
      "SUPER SHIFT, Y,      exec, zen-browser https://youtube.com/"

      # --- Window focus (HJKL vim-style, ported from bindings.conf) ---
      "SUPER, H, movefocus, l"
      "SUPER, L, movefocus, r"
      "SUPER, K, movefocus, u"
      "SUPER, J, movefocus, d"

      # Arrow-key focus kept for muscle memory
      "SUPER, left,  movefocus, l"
      "SUPER, right, movefocus, r"
      "SUPER, up,    movefocus, u"
      "SUPER, down,  movefocus, d"

      # --- Workspaces 1-9 ---
      "SUPER, 1, workspace, 1"
      "SUPER, 2, workspace, 2"
      "SUPER, 3, workspace, 3"
      "SUPER, 4, workspace, 4"
      "SUPER, 5, workspace, 5"
      "SUPER, 6, workspace, 6"
      "SUPER, 7, workspace, 7"
      "SUPER, 8, workspace, 8"
      "SUPER, 9, workspace, 9"
    ];

    bindm = [
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
    ];

    # Lid switch: run the user's clamshell script when the lid opens.
    # Path is resolved at runtime (the script is part of Omarchy's hypr/
    # tree, not yet ported into the repo — TODO if you want it on NixOS).
    bindl = [
      ",switch:Lid Switch, exec, ~/.config/hypr/clamshell_mode.sh open"
    ];

    # --- Window rules (ported from bindings.conf, with workspace-monitor
    # pinning removed and Slack→Legcord swap per review) ---
    windowrule = [
      # Per-class scroll factor (ported from input.conf windowrules)
      "match:class (Alacritty|kitty), scroll_touchpad 1.5"
      "match:class com.mitchellh.ghostty, scroll_touchpad 0.2"

      # Workspace assignments
      "workspace 1, match:class ^(.*[Ll]egcord.*)$"
      "workspace 2, match:title ^(.*Zen.*)$"
      "workspace 3, match:class ^(.*[Gg]hostty.*)$"
      "workspace 5, match:class ^(.*[Oo]bsidian.*)$"
    ];

    # Vicinae visual tweaks (kept even though it's not super+space-bound)
    layerrule = [
      "blur on, match:namespace vicinae"
      "ignore_alpha 0, match:namespace vicinae"
      "no_anim on, match:namespace vicinae"
    ];
  };
}
