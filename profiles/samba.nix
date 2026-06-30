{...}: {
  systemd.tmpfiles.rules = [
    "d /srv/storage 0755 dcard users - -"
  ];

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      storage = {
        path = "/srv/storage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "valid users" = "dcard";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
