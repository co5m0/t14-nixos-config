#!/usr/bin/env bash


if grep open /proc/acpi/button/lid/LID/state; then
    hyprctl keyword monitor "eDP-1, 2880x1800@120.00Hz, auto-left, 1.6"
else
    if [[ `hyprctl monitors | grep "Monitor" | wc -l` != 1 ]]; then
        hyprctl keyword monitor "eDP-1, disable"
    else
        systemctl suspend
    fi
fi
