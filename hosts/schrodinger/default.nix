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
    profiles.eidas
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
    # Hibernate resume target = disko swap partition.
    resumeDevice = "/dev/disk/by-partlabel/disk-main-swap";
  };
  # Critical battery action must be Hibernate: below ~5% the EC fires
  # "battery almost empty" wakeups out of S3, so suspend at critical battery
  # loops forever and drains the battery (observed 2026-08-31). Hibernate
  # powers off completely - a powered-off machine cannot be woken.
  services.upower.criticalPowerAction = "Hibernate";

  system.stateVersion = "26.05";
}
