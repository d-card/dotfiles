{
  inputs,
  profiles,
  ...
}: {
  imports = [
    profiles.core
    profiles.server
    profiles."home-server"
    profiles.ssh-server
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  networking = {
    hostId = "8425e349";
    useDHCP = true;
  };

  system.stateVersion = "26.05";
}
