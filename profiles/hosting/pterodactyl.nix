{
  config,
  pkgs,
  ...
}: let
  panelPort = 8090;
  panelDomain = "panel.dcard.pt";
  pterodactylDir = "/var/lib/pterodactyl";
in {
  # ---- MariaDB for Pterodactyl Panel ----
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = ["pterodactyl"];
    ensureUsers = [
      {
        name = "pterodactyl";
        ensurePermissions."pterodactyl.*" = "ALL PRIVILEGES";
      }
    ];
  };

  # ---- Redis for Pterodactyl Panel queues ----
  services.redis.servers.pterodactyl = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1 172.17.0.1";
  };

  # ---- Set MySQL password from generated env ----
  systemd.services.pterodactyl-db-setup = {
    description = "Apply Pterodactyl DB password";
    after = ["mysql.service"];
    requires = ["mysql.service"];
    wantedBy = ["multi-user.target"];
    path = [config.services.mysql.package];
    script = ''
      set -e
      if [ ! -f ${pterodactylDir}/env ]; then exit 0; fi
      PASSWORD=$(grep DB_PASSWORD ${pterodactylDir}/env | cut -d= -f2)
      if [ -z "$PASSWORD" ]; then exit 0; fi
      mysql -u root <<SQL
    ALTER USER pterodactyl@localhost IDENTIFIED BY "$PASSWORD";
    CREATE USER IF NOT EXISTS pterodactyl@"%" IDENTIFIED BY "$PASSWORD";
    GRANT ALL PRIVILEGES ON pterodactyl.* TO pterodactyl@"%";
    FLUSH PRIVILEGES;
    SQL
      echo "Pterodactyl DB user configured"
    '';
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
  };

  # ---- Provision Wings config from panel ----
  systemd.services.pterodactyl-wings-config = {
    description = "Generate Wings config from Panel";
    after = ["docker-pterodactyl-panel.service" "docker.service"];
    requires = ["docker-pterodactyl-panel.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.docker pkgs.curl];
    script = ''
      set -e
      for i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
        if curl -s -o /dev/null http://localhost:${toString panelPort}; then break; fi
        sleep 2
      done
      if docker exec pterodactyl-panel php artisan p:node:configuration 1 > /tmp/wings-config.yml 2>/dev/null; then
        docker run --rm -v pterodactyl_wings_config:/etc/pterodactyl -v /tmp/wings-config.yml:/tmp/src.yml:ro alpine:latest \
          sh -c "cp /tmp/src.yml /etc/pterodactyl/config.yml"
      else
        echo "Panel node not configured — run: docker exec pterodactyl-panel php artisan p:node:make"
      fi
    '';
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
  };

  # Pre-create pterodactyl Docker network to avoid subnet conflicts
  systemd.services.pterodactyl-network = {
    description = "Create Pterodactyl Docker Network";
    after = ["docker.service"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.docker];
    script = ''
      if ! docker network inspect pterodactyl_nw >/dev/null 2>&1; then
        docker network create --subnet=172.20.0.0/16 pterodactyl_nw
      fi
    '';
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
  };

  # Inject theme CSS import into panel (survives container restarts)
  # ---- Post-start fixup (theme, env, cache perms) ----
  systemd.services.pterodactyl-post-start = {
    description = "Pterodactyl post-start fixup";
    after = ["docker-pterodactyl-panel.service"];
    requires = ["docker-pterodactyl-panel.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.docker];
    script = ''
      docker cp ${./post-start.sh} pterodactyl-panel:/tmp/fixup.sh
      docker exec pterodactyl-panel sh /tmp/fixup.sh
    '';
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = false;
  };
  # ---- Generate env file with secrets once ----
  system.activationScripts.pterodactylSecrets = let
    envFile = "${pterodactylDir}/env";
  in ''
    mkdir -p ${pterodactylDir}/theme
    cp ${./theme.css} ${pterodactylDir}/theme/custom.css
    chmod 644 ${pterodactylDir}/theme/custom.css
    if [ ! -f ${envFile} ]; then
      cat > ${envFile} <<EOF
    APP_NAME=Zentryx
    APP_KEY=base64:Zuf3vGAzfWvxg3UXRmpgmphuOkqI08JZ1iyw/FoEmtU=
    HASHIDS_SALT=nY2PA4XOKnhHRNzT6c5DM78ydnjJ4t84
    DB_PASSWORD=$(${pkgs.openssl}/bin/openssl rand -base64 24)
    EOF
      chmod 600 ${envFile}
    fi
  '';

  # ---- Pterodactyl Panel ----
  virtualisation.oci-containers.containers.pterodactyl-panel = {
    image = "ghcr.io/pterodactyl/panel:latest";
    autoStart = true;
    ports = ["127.0.0.1:${toString panelPort}:80"];
    volumes = [
      "pterodactyl_panel_var:/app/var"
      "pterodactyl_panel_logs:/app/storage/logs"
    ];
    environment = {
      APP_NAME = "Zentryx";
      APP_KEY = "base64:Zuf3vGAzfWvxg3UXRmpgmphuOkqI08JZ1iyw/FoEmtU=";
      APP_URL = "https://panel.zentryx.pt";
      APP_TIMEZONE = "Europe/Lisbon";
      APP_ENV = "production";
      APP_ENVIRONMENT_ONLY = "false";
      CACHE_DRIVER = "file";
      SESSION_DRIVER = "file";
      QUEUE_DRIVER = "sync";
      DB_HOST = "host.docker.internal";
      DB_PORT = "3306";
      DB_DATABASE = "pterodactyl";
      DB_USERNAME = "pterodactyl";
      DB_PASSWORD = "raRn0Zl7k0cb7h0vhf+ddaDsSsfDVeOg";
      MAIL_DRIVER = "log";
      RECAPTCHA_ENABLED = "false";
    };
    extraOptions = [
      "--add-host=host.docker.internal:host-gateway"
      "--pull=always"
    ];
  };

  # ---- Pterodactyl Wings (needs Docker socket) ----
  virtualisation.oci-containers.containers.pterodactyl-wings = {
    image = "ghcr.io/pterodactyl/wings:latest";
    autoStart = true;
    ports = [
      "0.0.0.0:8081:8080" # Wings internal API
      "0.0.0.0:2022:2022" # SFTP
    ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:ro"
      "pterodactyl_wings_config:/etc/pterodactyl"
      "pterodactyl_wings_logs:/var/log/pterodactyl"
      "pterodactyl_wings_lib:/var/lib/pterodactyl"
      "/run/wings:/run/wings"
      "/srv/daemon-data:/srv/daemon-data"
    ];
    environment = {
      WINGS_UID = "988";
      WINGS_GID = "988";
      WINGS_USERNAME = "pterodactyl";
    };
    extraOptions = [
      "--pull=always"
      "--add-host=host.docker.internal:host-gateway"
    ];
  };

  # Open game server ports
  networking.firewall.allowedTCPPorts = [25565 25566];
  networking.firewall.allowedUDPPorts = [25565 25566];
  # Allow Docker containers to reach host services (MySQL, Redis)
  networking.firewall.trustedInterfaces = ["docker0"];
}
