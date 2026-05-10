{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER, Return,    exec, alacritty"
      "SUPER, Q,         killactive"
      "SUPER SHIFT, E,   exit"

      "SUPER, Space,     exec, dms ipc call spotlight toggle"
      "SUPER, L,         exec, dms ipc call lock lock"

      "SUPER, left,      movefocus, l"
      "SUPER, right,     movefocus, r"
      "SUPER, up,        movefocus, u"
      "SUPER, down,      movefocus, d"

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
  };
}
