{
  config,
  pkgs,
  secrets,
  ...
}: let
  cloudflaredKitchenowl = pkgs.writeShellScript "cloudflared-kitchenowl" ''
    exec ${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file "$CREDENTIALS_DIRECTORY/token"
  '';
in {
  age.secrets.cloudflareKitchenowlTunnelToken.file = secrets."cloudflare/kitchenowl-tunnel.age".file;

  system.activationScripts.kitchenowlSecrets.text = ''
    install -d -m 0750 /var/lib/kitchenowl

    if [ ! -e /var/lib/kitchenowl/kitchenowl.env ]; then
      printf 'JWT_SECRET_KEY=' > /var/lib/kitchenowl/kitchenowl.env
      ${pkgs.openssl}/bin/openssl rand -base64 48 >> /var/lib/kitchenowl/kitchenowl.env
    fi

    chmod 0600 /var/lib/kitchenowl/kitchenowl.env
  '';

  virtualisation.oci-containers.containers.kitchenowl = {
    image = "tombursch/kitchenowl:latest";
    autoStart = true;
    ports = ["127.0.0.1:3006:8080"];
    volumes = ["kitchenowl_data:/data"];
    environmentFiles = ["/var/lib/kitchenowl/kitchenowl.env"];
    environment = {
      FRONT_URL = "https://kitchenowl.dcard.pt";
      TZ = "Europe/Lisbon";
    };
  };

  systemd.services.cloudflared-kitchenowl = {
    description = "Cloudflare Tunnel for KitchenOwl";
    after = [
      "network-online.target"
      "docker-kitchenowl.service"
    ];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      DynamicUser = true;
      LoadCredential = "token:${config.age.secrets.cloudflareKitchenowlTunnelToken.path}";
      ExecStart = "${cloudflaredKitchenowl}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
