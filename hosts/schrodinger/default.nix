{profiles, ...}: {
  imports = [
    profiles.core
    profiles.laptop
    profiles.hardware.amd
    profiles.hardware.fingerprint
    profiles."desktop-plasma"
    profiles."personal-apps"
    profiles.ssh-server
  ];

  networking = {
    hostId = "1124b2fb";
    useDHCP = false;
  };

  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "usb_storage"
      "sd_mod"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/51a2fe76-2325-412f-8ffd-7afd4ce99be8";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/5653-9049";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/1ddd17f5-a8a7-4cdc-a42f-16657a60ea4b";}
  ];

  system.stateVersion = "26.05";
}
