# Always-on AltServer refresh daemon.
#
# Import `profiles.altserver` on the same host — this profile provides
# the alt-server systemd service that AltStore connects to for
# auto-refresh, plus netmuxd which replaces usbmuxd and handles BOTH
# USB and WiFi (mDNS) device discovery on the usbmuxd socket.
{
  pkgs,
  lib,
  ...
}: {
  # netmuxd replaces usbmuxd entirely (USB via nusb + mDNS network
  # discovery). System usbmuxd would fight it for /var/run/usbmuxd.
  services.usbmuxd.enable = lib.mkForce false;

  systemd.services.netmuxd = {
    description = "netmuxd - USB/WiFi multiplexer for iOS devices";
    after = ["network-online.target" "avahi-daemon.service"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      Environment = ["RUST_LOG=info"];
      ExecStart = "${pkgs.netmuxd}/bin/netmuxd --plist-storage /var/lib/lockdown";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  systemd.services.alt-server = {
    description = "AltServer daemon for AltStore refresh";
    after = ["network-online.target" "avahi-daemon.service" "netmuxd.service"];
    wants = ["network-online.target"];
    requires = ["netmuxd.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      Environment = [
        "PYTHONUNBUFFERED=1"
        "ALTSERVER_RCODESIGN=${pkgs.rcodesign}/bin/rcodesign"
        "ALTSERVER_ANISETTE_SERVER=http://127.0.0.1:6969/"
        "LD_LIBRARY_PATH=${pkgs.avahi-compat}/lib"
        "PATH=${pkgs.openssl}/bin:/run/current-system/sw/bin:/usr/bin:/bin"
      ];
      ExecStart = "${pkgs.altserver-ios26}/bin/alt-server";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
