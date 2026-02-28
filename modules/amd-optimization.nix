{ pkgs, ... }:

{
  boot.kernelParams = [
    # --- CPU & System ---
    "amd_pstate=active" # AMD P-State driver for better CPU power management
    "iommu=pt" # IOMMU passthrough for better performance

    # --- GPU: Kernel 6.18.2 + Aggressive Workarounds ---
    # Based on Arch Wiki (P14s Gen 6): https://wiki.archlinux.org/title/Lenovo_ThinkPad_P14s_(AMD)_Gen_6
    "amdgpu.dcdebugmask=0x10" # Arch Wiki: Fixes screen flickering & massive terminal lags

    # Aggressive workarounds for MES buffer saturation on Strix Point (gfx1150)
    "amdgpu.runpm=0" # Disable runtime PM - prevents GPU power state issues
    "amdgpu.mes=0" # Disable MES (Micro Engine Scheduler) - known to cause ring buffer hangs
    # amdgpu.gpu_recovery=1 REMOVED: taints kernel as "dangerous/support-ended" every boot,
    # no actual GPU hangs observed (MES already disabled, runpm=0 stable).
    # Re-enable only if gfx/sdma ring timeouts reappear in dmesg.

    # VPE (Video Processing Engine v6.1) fails to reset during s2idle suspend:
    # "amdgpu: VPE queue reset failed" → causes suspend instability on Strix Point.
    # amdgpu has no 'vpe=' param; use ip_block_mask instead.
    # IP blocks 0-10 = 0x7FF (all except block 11 = VPE).
    "amdgpu.ip_block_mask=0x7FF"
  ];

  # Force amdgpu driver early load
  boot.initrd.kernelModules = [ "amdgpu" ];

  hardware = {
    enableAllFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        # Vulkan support (moved from system packages)
        vulkan-loader

        # Video acceleration (Note: VPE disabled, using software encoding)
        libva-utils # VA-API utilities
        vaapiVdpau # VA-API to VDPAU translation
        libvdpau-va-gl # VDPAU support

        # Uncomment if you need OpenCL/ROCm support for GPU compute:
        # rocmPackages.clr.icd
      ];
    };
  };

  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      # CPU Performance Management
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # AMD-specific: CPU boost behavior
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Platform profiles (AMD-specific)
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # GPU Power Management (AMD)
      RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
      RADEON_DPM_PERF_LEVEL_ON_BAT = "low";
      RADEON_DPM_STATE_ON_AC = "performance";
      RADEON_DPM_STATE_ON_BAT = "battery";

      # PCIe Active State Power Management
      # Keep GPU PCIe at performance on AC to prevent stability issues
      PCIE_ASPM_ON_AC = "performance";
      # powersupersave safe here: amdgpu.runpm=0 already holds GPU state,
      # no risk of PCIe instability caused by aggressive ASPM on GPU link.
      PCIE_ASPM_ON_BAT = "powersupersave";

      # USB autosuspend (useful for battery, but exclude input devices)
      USB_AUTOSUSPEND = 1;
      USB_EXCLUDE_BTUSB = 1; # Don't suspend Bluetooth
      USB_EXCLUDE_PHONE = 1; # Don't suspend tethered phones
      # Synaptics fingerprint reader (06cb:00f9): loses state after s2idle resume,
      # causing fprintd "device disconnected" errors. Exclude from autosuspend.
      USB_DENYLIST = "06cb:00f9";

      # Battery Charge Thresholds (40-80% for longevity)
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };
}
