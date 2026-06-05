{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      # --- Core ---
      "SUPER, Return,    exec, ghostty"
      "SUPER ALT, Return, exec, ghostty -e tmux new"
      "SUPER, Q,         killactive"
      "SUPER SHIFT, E,   exit"
      "SUPER, F,   fullscreen"

      # --- DMS shell (Super+Space owned by DMS spotlight; vicinae runs in
      # background via exec-once but isn't keybound) ---
      "SUPER, Space,     exec, dms ipc call spotlight toggle"
      "SUPER SHIFT CTRL, L,         exec, dms ipc call lock lock"

      # --- App launchers (translated from Omarchy helpers; flatpak/nix paths) ---
      "SUPER SHIFT, Return, exec, zen-browser"
      "SUPER SHIFT, B,      exec, zen-browser"
      "SUPER SHIFT ALT, B,  exec, zen-browser --private"
      "SUPER SHIFT, M,      exec, flatpak run com.spotify.Client"
      "SUPER SHIFT, N,      exec, ghostty -e nvim"
      "SUPER SHIFT, T,      exec, ghostty -e btop"
      "SUPER SHIFT, D,      exec, ghostty -e lazydocker"
      "SUPER SHIFT, O,      exec, obsidian --enable-wayland-ime"
      "SUPER SHIFT, W,      exec, typora --enable-wayland-ime"
      "SUPER SHIFT, Y,      exec, zen-browser https://youtube.com/"

      # --- Screenshot: hyprshot region → satty for annotation; save to
      # ~/Pictures/Screenshots and copy the edited result to clipboard.
      ", Print, exec, bash -c 'mkdir -p ~/Pictures/Screenshots && hyprshot -m region --raw | satty --filename - --output-filename ~/Pictures/Screenshots/satty-$(date +%Y%m%d-%H%M%S).png --early-exit --copy-command wl-copy'"

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

      # Move the active window with mainMod + SHIFT + hjkl
      "SUPER SHIFT, h, movewindow, l"
      "SUPER SHIFT, j, movewindow, d"
      "SUPER SHIFT, k, movewindow, u"
      "SUPER SHIFT, l, movewindow, r"

      # SUPER window with mainMod + CTRL + hjkl (bonus, very vim-like)
      "SUPER CTRL, h, resizeactive, -40 0"
      "SUPER CTRL, j, resizeactive, 0 40"
      "SUPER CTRL, k, resizeactive, 0 -40"
      "SUPER CTRL, l, resizeactive, 40 0"

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

      # --- Move active window to workspace 1-9 ---
      "SUPER SHIFT, 1, movetoworkspace, 1"
      "SUPER SHIFT, 2, movetoworkspace, 2"
      "SUPER SHIFT, 3, movetoworkspace, 3"
      "SUPER SHIFT, 4, movetoworkspace, 4"
      "SUPER SHIFT, 5, movetoworkspace, 5"
      "SUPER SHIFT, 6, movetoworkspace, 6"
      "SUPER SHIFT, 7, movetoworkspace, 7"
      "SUPER SHIFT, 8, movetoworkspace, 8"
      "SUPER SHIFT, 9, movetoworkspace, 9"

      # --- Groups (tabbed window stacks) ---
      "SUPER, G,         togglegroup"
      "SUPER, Tab,       changegroupactive, f"
      "SUPER SHIFT, Tab, changegroupactive, b"

      # Jump directly to tab N inside the current group
      "SUPER ALT, 1, changegroupactive, 1"
      "SUPER ALT, 2, changegroupactive, 2"
      "SUPER ALT, 3, changegroupactive, 3"
      "SUPER ALT, 4, changegroupactive, 4"
      "SUPER ALT, 5, changegroupactive, 5"
      "SUPER ALT, 6, changegroupactive, 6"
      "SUPER ALT, 7, changegroupactive, 7"
      "SUPER ALT, 8, changegroupactive, 8"
      "SUPER ALT, 9, changegroupactive, 9"
    ];

    bindm = [
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
    ];

    # Locked + repeat: level adjusts must repeat while held and keep
    # working from the lock screen. Routed through DMS IPC so the shell
    # renders its OSD popup instead of silently bumping the level.
    bindel = [
      ",XF86AudioRaiseVolume,  exec, dms ipc call audio increment 5"
      ",XF86AudioLowerVolume,  exec, dms ipc call audio decrement 5"
      ",XF86MonBrightnessUp,   exec, dms ipc call brightness increment 5 \"\""
      ",XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5 \"\""
      ",XF86KbdBrightnessUp,   exec, dms ipc call brightness increment 10 leds:tpacpi::kbd_backlight"
      ",XF86KbdBrightnessDown, exec, dms ipc call brightness decrement 10 leds:tpacpi::kbd_backlight"
    ];

    # Locked (no repeat): toggles + media transport keep firing even when
    # the screen is locked. Lid switch runs the clamshell script when the
    # lid opens (script lives in Omarchy's hypr/ tree, not yet ported
    # into this repo — TODO).
    bindl = [
      ",XF86AudioMute,    exec, dms ipc call audio mute"
      ",XF86AudioMicMute, exec, dms ipc call audio micmute"
      ",XF86AudioPlay,    exec, playerctl play-pause"
      ",XF86AudioPause,   exec, playerctl play-pause"
      ",XF86AudioNext,    exec, playerctl next"
      ",XF86AudioPrev,    exec, playerctl previous"

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

      # Float browser Picture-in-Picture popups and keep them on top
      "float on, match:title ^(Picture.?in.?[Pp]icture)$"
      "size 480 270, match:title ^(Picture-in-Picture)$"

      # Float satty (screenshot annotator)
      "float on, match:class ^(com\\.gabm\\.satty)$"
    ];

    # Vicinae visual tweaks (kept even though it's not super+space-bound)
    layerrule = [
      "blur on, match:namespace vicinae"
      "ignore_alpha 0, match:namespace vicinae"
      "no_anim on, match:namespace vicinae"
    ];
  };
}
