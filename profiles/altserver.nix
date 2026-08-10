# AltServer-Linux base: iOS device access + signing support.
#
# Import on any host that installs or signs iOS apps. Provides avahi
# (Bonjour), usbmuxd, the CA fix, the kernel module blacklist, and the
# patched alt-server binaries.
#
# For the always-on AltStore refresh daemon (netmuxd + alt-server
# service), also import `profiles.altserver-daemon`.
{
  pkgs,
  lib,
  ...
}: {
  # Bonjour/mDNS for AltServer discovery and WiFi pairing.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    package = pkgs.avahi-compat;
    publish = {
      enable = true;
      workstation = true;
      userServices = true;
    };
  };

  # Alpine-built alt-server's libressl looks for CA certs here.
  environment.etc."ssl/cert.pem".source = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  # These kernel modules hijack the iPhone and cause reconnect loops.
  boot.blacklistedKernelModules = ["apple-mfi-fastcharge" "ipheth"];
  # iPhone connectivity: netmuxd (see profiles/altserver-daemon.nix) replaces
  # usbmuxd and handles both USB and WiFi devices. usbmuxd is disabled there.

  environment.systemPackages = with pkgs; [
    altserver-linux
    altserver-ios26
    avahi-compat
    libimobiledevice
    ideviceinstaller
    netmuxd
    python3
    rcodesign
  ];

  # AltServer picks a random high port; iOS apps are large.
  networking.firewall.allowedTCPPortRanges = [
    {from = 1024; to = 65535;}
  ];
}
