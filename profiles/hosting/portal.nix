{
  config,
  pkgs,
  lib,
  ...
}: let
  portalPort = 8000;
  portalDomain = "portal.dcard.pt";
  portalDir = "/var/lib/hosting-portal";

  portalPython = pkgs.python3.withPackages (ps:
    with ps; [
      fastapi
      uvicorn
      httpx
      psycopg2
      python-jose
      passlib
      bcrypt
      pydantic
      email-validator
      stripe
      alembic
    ]);

  portalSource = ../../services/portal;
in {
  services.postgresql = {
    enable = true;
    ensureDatabases = ["hosting_portal"];
    ensureUsers = [
      {
        name = "hosting_portal";
        ensureDBOwnership = true;
      }
    ];
    authentication = ''
      local hosting_portal hosting_portal trust
    '';
  };

  # ---- Generate portal secret key once ----
  system.activationScripts.hostingPortalSecret = ''
    mkdir -p ${portalDir}
    chown hosting-portal:hosting-portal ${portalDir}
    if [ ! -f ${portalDir}/secret_key ]; then
      ${pkgs.openssl}/bin/openssl rand -hex 32 > ${portalDir}/secret_key
      chmod 600 ${portalDir}/secret_key
      chown hosting-portal:hosting-portal ${portalDir}/secret_key
    fi
  '';

  # ---- Portal API service ----
  systemd.services.hosting-portal = {
    description = "Hosting Portal API";
    after = ["network.target" "postgresql.service"];
    requires = ["postgresql.service"];
    wantedBy = ["multi-user.target"];

    path = [portalPython pkgs.incus];

    environment = {
      DATABASE_URL = "postgresql://hosting_portal@/hosting_portal?host=/run/postgresql";
      SECRET_KEY_FILE = "${portalDir}/secret_key";
      INCUS_SOCKET = "/var/lib/incus/unix.socket";
      PTERODACTYL_URL = "http://127.0.0.1:8090";
      PTERODACTYL_API_KEY_FILE = "${portalDir}/pterodactyl_api_key";
      # Stripe keys — set via agenix or manual file later
      STRIPE_SECRET_KEY_FILE = "${portalDir}/stripe_secret";
      STRIPE_WEBHOOK_SECRET_FILE = "${portalDir}/stripe_webhook_secret";
      HOME = "${portalDir}";
    };

    serviceConfig = {
      Type = "simple";
      User = "hosting-portal";
      Group = "hosting-portal";
      WorkingDirectory = "${portalSource}";
      ExecStart = "${portalPython}/bin/uvicorn main:app --host 0.0.0.0 --port ${toString portalPort}";
      Restart = "on-failure";
      RestartSec = "5s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = "${portalDir} /run/postgresql";
      ReadOnlyPaths = "/var/lib/incus";
    };
  };
  # ---- Portal user and group ----
  users.users.hosting-portal = {
    isSystemUser = true;
    group = "hosting-portal";
    extraGroups = ["incus" "incus-admin"];
  };
  users.groups.hosting-portal = {};
}
