{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  domain = "zentryx.pt";

  hostingDomains =
    if domain != null
    then ["panel.${domain}" "portal.${domain}"]
    else [];

  cloudflareCert =
    if domain != null
    then {
      group = "nginx";
      dnsProvider = "cloudflare";
      credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
        config.age.secrets.cloudflareToken.path;
    }
    else {};
in {
  imports = [
    ./incus.nix
    ./pterodactyl.nix
    ./portal.nix
  ];

  security.acme.certs =
    lib.optionalAttrs (domain != null)
    (lib.genAttrs hostingDomains (_: cloudflareCert));

  services.nginx.virtualHosts =
    lib.optionalAttrs (domain != null) {
      "panel.${domain}" = {
        forceSSL = false;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8090";
          proxyWebsockets = true;
        };
      };

      "portal.${domain}" = {
        forceSSL = false;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8000";
          proxyWebsockets = true;
        };
      };
    };

  networking.firewall.allowedTCPPorts =
    lib.optionals (domain == null) [8000 8090];

  # Cloudflare Tunnel — routes panel.zentryx.pt and portal.zentryx.pt → nginx
  age.secrets.cloudflareZentryxTunnelToken.file = secrets."cloudflare/zentryx-tunnel.age".file;

  systemd.services.cloudflared-zentryx = {
    description = "Cloudflare Tunnel for zentryx.pt";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      DynamicUser = true;
      LoadCredential = "token:${config.age.secrets.cloudflareZentryxTunnelToken.path}";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file \${CREDENTIALS_DIRECTORY}/token";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
