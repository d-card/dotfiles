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
    profiles.mosquitto
    profiles.tailscale
    profiles.altserver
    profiles."altserver-daemon"
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  networking = {
    hostId = "8425e349";
    useDHCP = true;
  };

  system.stateVersion = "26.05";
}
