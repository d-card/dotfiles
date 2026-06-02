{
  config,
  inputs,
  profiles,
  ...
}: {
  imports = with profiles; [
    core
    server
    containers
    dns
    home-assistant
    monitoring
    acme-cloudflare
    reverse-proxy
    ssh-server
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  networking = {
    hostId = "8425e349";
    useDHCP = true;
  };

  security.acme.certs."portainer.dcard.pt" = {
    group = "nginx";
    dnsProvider = "cloudflare";
    credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
      config.age.secrets.cloudflareToken.path;
  };
  security.acme.certs."adguard.dcard.pt" = {
    group = "nginx";
    dnsProvider = "cloudflare";
    credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
      config.age.secrets.cloudflareToken.path;
  };
  security.acme.certs."home-assistant.dcard.pt" = {
    group = "nginx";
    dnsProvider = "cloudflare";
    credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
      config.age.secrets.cloudflareToken.path;
  };
  security.acme.certs."status.dcard.pt" = {
    group = "nginx";
    dnsProvider = "cloudflare";
    credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
      config.age.secrets.cloudflareToken.path;
  };
  security.acme.certs."grafana.dcard.pt" = {
    group = "nginx";
    dnsProvider = "cloudflare";
    credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
      config.age.secrets.cloudflareToken.path;
  };

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
  };

  services.adguardhome.settings.filtering.rewrites = [
    {
      domain = "portainer.dcard.pt";
      answer = "192.168.1.237";
      enabled = true;
    }
    {
      domain = "adguard.dcard.pt";
      answer = "192.168.1.237";
      enabled = true;
    }
    {
      domain = "home-assistant.dcard.pt";
      answer = "192.168.1.237";
      enabled = true;
    }
    {
      domain = "status.dcard.pt";
      answer = "192.168.1.237";
      enabled = true;
    }
    {
      domain = "grafana.dcard.pt";
      answer = "192.168.1.237";
      enabled = true;
    }
  ];

  system.stateVersion = "26.05";
}
