{ config, pkgs, ... }:

{
  services.flatpak = {
    enable = true;
    remotes = [{
      name = "flathub";
      location = "https://flathub.org/repo/flathub.flatpakrepo";
    }];
    packages = [
      "com.logseq.Logseq"
      "com.github.tchx84.Flatseal"
      "org.libreoffice.LibreOffice"
      "com.spotify.Client"
      "com.actualbudget.actual"

      # Browsers (sandboxed)
      "org.mozilla.firefox"
      "org.chromium.Chromium"

      # Common comms/chat (optional - uncomment if needed)
      "org.telegram.desktop"
      "com.discordapp.Discord"
      "com.slack.Slack"
      "org.signal.Signal"

      # Task Managers (optional - uncomment if needed)
      "com.super_productivity.SuperProductivity"

      # Notes/PKM (optional - uncomment if needed)
      # "md.obsidian.Obsidian"

      # Secrets (optional - uncomment if needed)
      # "org.keepassxc.KeePassXC"

      # Gaming (optional - uncomment if needed)
      # "com.valvesoftware.Steam"
    ];
    update.onActivation = true;
    uninstallUnmanaged = true;
  };
}
