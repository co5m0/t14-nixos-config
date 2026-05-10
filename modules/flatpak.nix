{ config, pkgs, ... }:

{
  services.flatpak = {
    enable = true;
    remotes = [
      {
        name = "flathub";
        location = "https://flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      "org.libreoffice.LibreOffice"
      "com.spotify.Client"

      # Browsers (sandboxed)
      "org.chromium.Chromium"

      # Common comms/chat (optional - uncomment if needed)
      "org.telegram.desktop"
      # Discord installed natively via home.nix (better Wayland screen sharing)

      # Notes/PKM (optional - uncomment if needed)
      "md.obsidian.Obsidian"

      # Secrets (optional - uncomment if needed)
      # "org.keepassxc.KeePassXC"

      # Gaming (optional - uncomment if needed)
      # "com.valvesoftware.Steam"
    ];
    update.onActivation = true;
    uninstallUnmanaged = true;
  };
}
