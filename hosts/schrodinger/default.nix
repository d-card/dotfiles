{inputs, profiles, ...}: {
  imports = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    profiles.core
    profiles.laptop
    profiles.hardware.amd
    profiles.hardware.fingerprint
    profiles."desktop-plasma"
    profiles."user-packages"
    profiles.secrets
    profiles.ssh-server
  ];

  networking = {
    hostId = "1124b2fb";
  };

  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "usb_storage"
      "sd_mod"
    ];
  };

  system.stateVersion = "26.05";
}
