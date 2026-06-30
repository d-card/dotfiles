{pkgs, ...}: {
  networking.networkmanager.enable = true;

  hardware = {
    bluetooth.enable = true;
    enableRedistributableFirmware = true;
  };

  services = {
    blueman.enable = true;
    fwupd.enable = true;
    libinput = {
      enable = true;
      touchpad.naturalScrolling = true;
    };
    power-profiles-daemon.enable = true;
    printing.enable = true;
    thermald.enable = true;
  };

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };

  programs = {
    virt-manager.enable = true;
  };

  users.users.dcard.extraGroups = [
    "adbusers"
    "docker"
    "libvirtd"
    "networkmanager"
    "video"
  ];
}
