{
  config,
  lib,
  profiles,
  ...
}: let
  serverAddress = "192.168.1.237";

  domains = [
    "portainer.dcard.pt"
    "adguard.dcard.pt"
    "home-assistant.dcard.pt"
    "status.dcard.pt"
    "grafana.dcard.pt"
    "homepage.dcard.pt"
    "tools.dcard.pt"
    "pdf.dcard.pt"
    "kitchenowl.dcard.pt"
    "ntfy.dcard.pt"
    "paste.dcard.pt"
  ];

  cloudflareCert = {
    group = "nginx";
    dnsProvider = "cloudflare";
    credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
      config.age.secrets.cloudflareToken.path;
  };
in {
    imports = with profiles; [
    containers
    dns
    home-assistant
    profiles.apps.homepage
    profiles.apps."it-tools"
    profiles.apps.kitchenowl
    profiles.apps."stirling-pdf"
    profiles.apps.ntfy
    profiles.apps.privatebin
    profiles.apps."uptime-kuma"
    monitoring
    maintenance
    acme-cloudflare
    reverse-proxy
    samba
  ];

  security.acme.certs = lib.genAttrs domains (_: cloudflareCert);

  services.nginx.virtualHosts = {
    "portainer.dcard.pt" = {
      forceSSL = true;
      useACMEHost = "portainer.dcard.pt";
      locations."/".proxyPass = "https://127.0.0.1:9443";
      extraConfig = ''
        proxy_ssl_verify off;
      '';
    };

    "adguard.dcard.pt" = {
      forceSSL = true;
      useACMEHost = "adguard.dcard.pt";
      locations."/".proxyPass = "http://127.0.0.1:3000";
    };

    "home-assistant.dcard.pt" = {
      forceSSL = true;
      useACMEHost = "home-assistant.dcard.pt";
      locations."/" = {
        proxyPass = "http://127.0.0.1:8123";
        proxyWebsockets = true;
      };
    };

    "status.dcard.pt" = {
      forceSSL = true;
      useACMEHost = "status.dcard.pt";
      locations."/" = {
        proxyPass = "http://127.0.0.1:3001";
        proxyWebsockets = true;
      };
    };

    "grafana.dcard.pt" = {
      forceSSL = true;
      useACMEHost = "grafana.dcard.pt";
      locations."/" = {
        proxyPass = "http://127.0.0.1:3002";
        proxyWebsockets = true;
      };
    };

    "homepage.dcard.pt" = {
      forceSSL = true;
      useACMEHost = "homepage.dcard.pt";
      locations."/".proxyPass = "http://127.0.0.1:3003";
    };

    "tools.dcard.pt" = {
      forceSSL = true;
      useACMEHost = "tools.dcard.pt";
      locations."/".proxyPass = "http://127.0.0.1:3004";
    };

    "pdf.dcard.pt" = {
      forceSSL = true;
      useACMEHost = "pdf.dcard.pt";
      locations."/".proxyPass = "http://127.0.0.1:3005";
    };

    "kitchenowl.dcard.pt" = {
      forceSSL = true;
      useACMEHost = "kitchenowl.dcard.pt";
      locations."/" = {
        proxyPass = "http://127.0.0.1:3006";
        proxyWebsockets = true;
      };
    };

    "ntfy.dcard.pt" = {
      forceSSL = true;
      useACMEHost = "ntfy.dcard.pt";
      locations."/" = {
        proxyPass = "http://127.0.0.1:3007";
        proxyWebsockets = true;
      };
    };

    "paste.dcard.pt" = {
      forceSSL = true;
      useACMEHost = "paste.dcard.pt";
      locations."/".proxyPass = "http://127.0.0.1:3008";
    };
  };

  services.adguardhome.settings = {
    querylog = {
      ignored_enabled = true;
      ignored = ["||dcard.pt^"];
    };

    statistics = {
      ignored_enabled = true;
      ignored = ["||dcard.pt^"];
    };

    filtering.rewrites =
      map (domain: {
        inherit domain;
        answer = serverAddress;
        enabled = true;
      })
      domains;
  };
}
