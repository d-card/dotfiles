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
    profiles.apps.homepage
    profiles.apps."it-tools"
    profiles.apps.kitchenowl
    profiles.apps."stirling-pdf"
    profiles.apps.ntfy
    profiles.apps.privatebin
    monitoring
    maintenance
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
  security.acme.certs."homepage.dcard.pt" = {
    group = "nginx";
    dnsProvider = "cloudflare";
    credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
      config.age.secrets.cloudflareToken.path;
  };
  security.acme.certs."tools.dcard.pt" = {
    group = "nginx";
    dnsProvider = "cloudflare";
    credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
      config.age.secrets.cloudflareToken.path;
  };
  security.acme.certs."pdf.dcard.pt" = {
    group = "nginx";
    dnsProvider = "cloudflare";
    credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
      config.age.secrets.cloudflareToken.path;
  };
  security.acme.certs."kitchenowl.dcard.pt" = {
    group = "nginx";
    dnsProvider = "cloudflare";
    credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
      config.age.secrets.cloudflareToken.path;
  };
  security.acme.certs."ntfy.dcard.pt" = {
    group = "nginx";
    dnsProvider = "cloudflare";
    credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
      config.age.secrets.cloudflareToken.path;
  };
  security.acme.certs."paste.dcard.pt" = {
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
    {
      domain = "homepage.dcard.pt";
      answer = "192.168.1.237";
      enabled = true;
    }
    {
      domain = "tools.dcard.pt";
      answer = "192.168.1.237";
      enabled = true;
    }
    {
      domain = "pdf.dcard.pt";
      answer = "192.168.1.237";
      enabled = true;
    }
    {
      domain = "kitchenowl.dcard.pt";
      answer = "192.168.1.237";
      enabled = true;
    }
    {
      domain = "ntfy.dcard.pt";
      answer = "192.168.1.237";
      enabled = true;
    }
    {
      domain = "paste.dcard.pt";
      answer = "192.168.1.237";
      enabled = true;
    }
  ];

  system.stateVersion = "26.05";
}
