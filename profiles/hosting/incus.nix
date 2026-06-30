{
  config,
  lib,
  pkgs,
  ...
}: {
  # Incus requires nftables on NixOS
  networking.nftables.enable = true;

  # KVM kernel modules for virtualisation
  boot.kernelModules = ["kvm-intel"];

  # Incus — LXC containers + KVM VMs
  # NOTE: AdGuard currently owns port 53, so DHCP is disabled on incusbr0.
  # Once AdGuard is moved to a different port or bound to specific interfaces,
  # re-enable with: incus network set incusbr0 ipv4.dhcp=true
  virtualisation.incus = {
    enable = true;
    preseed = {
      networks = [
        {
          name = "incusbr0";
          type = "bridge";
          config = {
            "ipv4.address" = "10.43.0.1/24";
            "ipv4.nat" = "true";
            "ipv4.dhcp" = "false";
            "dns.mode" = "none";
            "ipv6.address" = "none";
          };
        }
      ];
      storage_pools = [
        {
          name = "default";
          driver = "dir";
          config.source = "/var/lib/incus/storage-pools/default";
        }
      ];
      profiles = [
        {
          name = "default";
          devices = {
            root = {
              type = "disk";
              path = "/";
              pool = "default";
            };
            eth0 = {
              type = "nic";
              network = "incusbr0";
              name = "eth0";
            };
          };
        }
      ];
    };
  };

  # Allow incus bridge traffic through firewall
  networking.firewall.trustedInterfaces = ["incusbr0"];

  # Give dcard incus admin access
  users.users.dcard.extraGroups = ["incus-admin"];
}
