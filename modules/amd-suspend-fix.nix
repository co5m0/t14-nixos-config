{ pkgs, ... }:

{
  # Systemd service to handle AMD GPU stability after suspend/resume
  # Addresses MES (Micro Engine Scheduler) ring buffer saturation on Strix Point

  # Systemd-logind configuration for proper suspend/hibernate handling
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "suspend";

    HandlePowerKey = "suspend";
    HandleSuspendKey = "suspend";
    HandleHibernateKey = "ignore";

    # DMS handles screen blanking / idle.
    IdleAction = "ignore";
    IdleActionSec = "30min";

    # Don't kill user processes on logout (tmux/screen sessions).
    KillUserProcesses = false;
  };

  systemd.services.amdgpu-suspend-fix = {
    description = "AMD GPU stability workaround for suspend/resume";
    wantedBy = [ "suspend.target" ];
    before = [ "suspend.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "amdgpu-pre-suspend" ''
        # Log GPU state before suspend
        echo "AMD GPU pre-suspend: $(date)" >> /var/log/amdgpu-suspend.log

        # Force flush of GPU caches
        sync

        # Drop GPU memory caches if possible
        if [ -w /proc/sys/vm/drop_caches ]; then
          echo 3 > /proc/sys/vm/drop_caches
        fi
      '';
    };
  };

  systemd.services.amdgpu-resume-fix = {
    description = "AMD GPU recovery after suspend/resume";
    wantedBy = [ "suspend.target" ];
    after = [ "suspend.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "amdgpu-post-resume" ''
        # Log resume event
        echo "AMD GPU post-resume: $(date)" >> /var/log/amdgpu-suspend.log

        # Wait for GPU to stabilize
        sleep 2

        # Check for MES errors in recent dmesg
        if dmesg | tail -50 | grep -q "MES.*failed\|MES ring buffer"; then
          echo "WARNING: MES errors detected after resume" >> /var/log/amdgpu-suspend.log

          # Attempt to reset DRM subsystem by restarting display manager
          # This is less invasive than full driver reload
          systemctl restart display-manager || true
        fi
      '';
    };
  };

  # Create log file with proper permissions
  systemd.tmpfiles.rules = [
    "f /var/log/amdgpu-suspend.log 0644 root root -"
  ];

  # Kernel module options for better s2idle stability on Strix Point
  boot.extraModprobeConfig = ''
    # AMD GPU: Ensure MES scheduler stays disabled (backup to kernel param)
    options amdgpu mes=0 runpm=0 gpu_recovery=1

    # Note: xhci_hcd quirks=0x0200 (RESET_ON_RESUME) was removed because it
    # breaks isochronous USB transfers, causing webcam streaming to fail
    # (STREAMON succeeds but DQBUF times out — no frames delivered).
  '';
}
