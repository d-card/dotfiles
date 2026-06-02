{lib, ...}: let
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCrf5FKQmZRA9ip4s/fOt1PVg+90k6tvEoDkCnPq1qL @oppenheimer"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMOK0uyFwBEoBHuqXsrWZOAMROsDYGjzwEUmrAhz5jfr @schrodinger"
  ];
in {
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      # UseDNS = true;
      PermitRootLogin = "without-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
  };
  users.users = {
    root.openssh.authorizedKeys.keys = authorizedKeys;
    dcard.openssh.authorizedKeys.keys = authorizedKeys;
  };
}
