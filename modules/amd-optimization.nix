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
    "amdgpu.gpu_recovery=1" # Enable GPU recovery for ring timeout/hang scenarios (taints kernel but needed for stability)
    "amdgpu.lockup_timeout=10000" # Increase timeout for GPU operations (10 seconds)
    "amdgpu.noretry=0" # Enable retries for failed operations

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
        libva-vdpau-driver # VA-API to VDPAU translation (renamed from vaapiVdpau)
        libvdpau-va-gl # VDPAU support

        # Uncomment if you need OpenCL/ROCm support for GPU compute:
        # rocmPackages.clr.icd
      ];
    };
  };

  # Udev rules for AMD GPU stability
  services.udev.extraRules = ''
    # AMD Strix Point GPU - Force specific power management settings
    # Prevents aggressive power state transitions that can trigger MES hangs
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1002", ATTR{device}=="0x1114", \
      ATTR{power/control}="on"

    # Keep GPU DRM device always active
    ACTION=="add", SUBSYSTEM=="drm", KERNEL=="card1", \
      ATTR{device/power/control}="on"
  '';

  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      # CPU Performance Management
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_power";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # AMD-specific: CPU boost behavior
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Platform profiles (AMD-specific)
      PLATFORM_PROFILE_ON_AC = "balanced";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # GPU Power Management (AMD)
      RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
      RADEON_DPM_PERF_LEVEL_ON_BAT = "low";
      RADEON_DPM_STATE_ON_AC = "performance";
      RADEON_DPM_STATE_ON_BAT = "battery";

      # PCIe Active State Power Management
      # CRITICAL: With amdgpu.runpm=0 (GPU runtime PM disabled), PCIe ASPM must be
      # conservative to avoid GPU communication issues during suspend/resume cycles.
      PCIE_ASPM_ON_AC = "performance";
      # Use 'default' instead of 'powersupersave' on battery to prevent PCIe link
      # instability with GPU when combined with amdgpu.runpm=0
      PCIE_ASPM_ON_BAT = "default";

      # Runtime Power Management for PCI(e) devices
      # 'on' = disable runtime PM (compatible with amdgpu.runpm=0)
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # Exclude AMD GPU from runtime PM (already handled by amdgpu.runpm=0 kernel param)
      # AMD Strix Point GPU is at PCI address c4:00.0 (0000:c4:00.0)
      RUNTIME_PM_DENYLIST = "c4:00.0";

      # USB autosuspend (now properly managed without kernel param conflict)
      USB_AUTOSUSPEND = 1;
      USB_EXCLUDE_BTUSB = 1; # Don't suspend Bluetooth
      USB_EXCLUDE_PHONE = 1; # Don't suspend tethered phones
      # Synaptics fingerprint reader (06cb:00f9): loses state after s2idle resume,
      # causing fprintd "device disconnected" errors. Exclude from autosuspend.
      # Chicony Integrated Camera (04f2:b840): fails to wake from USB autosuspend,
      # causing corrupted/frozen video stream in browsers.
      USB_DENYLIST = "06cb:00f9 04f2:b840";

      # Suspend/Resume optimization for AMD
      # Restore radio device state after suspend (WiFi/Bluetooth)
      RESTORE_DEVICE_STATE_ON_STARTUP = 1;

      # Battery Charge Thresholds (60-80% for longevity)
      START_CHARGE_THRESH_BAT0 = 60;
      STOP_CHARGE_THRESH_BAT0 = 90;
    };
  };
}
