{pkgs, ...}: let
  blackboxConfig = pkgs.writeText "blackbox-exporter.yml" (builtins.toJSON {
    modules.http_2xx = {
      prober = "http";
      timeout = "10s";
      http = {
        method = "GET";
        preferred_ip_protocol = "ip4";
        valid_status_codes = [
          200
          301
          302
          401
          403
        ];
      };
    };
  });
in {
  system.activationScripts.grafanaSecrets.text = ''
    install -d -m 0750 -o grafana -g grafana /var/lib/grafana

    if [ ! -e /var/lib/grafana/secret_key ]; then
      ${pkgs.openssl}/bin/openssl rand -base64 48 > /var/lib/grafana/secret_key
    fi

    if [ ! -e /var/lib/grafana/admin_password ]; then
      ${pkgs.openssl}/bin/openssl rand -base64 24 > /var/lib/grafana/admin_password
    fi

    chown grafana:grafana /var/lib/grafana/secret_key
    chmod 0400 /var/lib/grafana/secret_key
    chown root:grafana /var/lib/grafana/admin_password
    chmod 0440 /var/lib/grafana/admin_password
  '';

  services.prometheus = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9090;
    retentionTime = "30d";

    exporters = {
      blackbox = {
        enable = true;
        port = 9115;
        configFile = blackboxConfig;
      };

      nginx = {
        enable = true;
        port = 9113;
      };

      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "processes"
        ];
        port = 9100;
      };

      smartctl = {
        enable = true;
        port = 9633;
      };
    };

    scrapeConfigs = [
      {
        job_name = "maxwell-services";
        metrics_path = "/probe";
        params.module = ["http_2xx"];
        static_configs = [
          {
            targets = [
              "https://portainer.dcard.pt"
              "https://adguard.dcard.pt"
              "https://home-assistant.dcard.pt"
              "https://status.dcard.pt"
              "https://grafana.dcard.pt"
            ];
            labels.instance = "maxwell";
          }
        ];
        relabel_configs = [
          {
            source_labels = ["__address__"];
            target_label = "__param_target";
          }
          {
            source_labels = ["__param_target"];
            target_label = "target";
          }
          {
            target_label = "__address__";
            replacement = "127.0.0.1:9115";
          }
        ];
      }
      {
        job_name = "maxwell-nginx";
        static_configs = [
          {
            targets = ["127.0.0.1:9113"];
            labels.instance = "maxwell";
          }
        ];
      }
      {
        job_name = "maxwell-docker";
        static_configs = [
          {
            targets = ["127.0.0.1:9323"];
            labels.instance = "maxwell";
          }
        ];
      }
      {
        job_name = "maxwell-node";
        static_configs = [
          {
            targets = ["127.0.0.1:9100"];
            labels.instance = "maxwell";
          }
        ];
      }
      {
        job_name = "maxwell-smartctl";
        static_configs = [
          {
            targets = ["127.0.0.1:9633"];
            labels.instance = "maxwell";
          }
        ];
      }
      {
        job_name = "maxwell-cadvisor";
        static_configs = [
          {
            targets = ["127.0.0.1:8080"];
            labels.instance = "maxwell";
          }
        ];
      }
      {
        job_name = "maxwell-prometheus";
        static_configs = [
          {
            targets = ["127.0.0.1:9090"];
            labels.instance = "maxwell";
          }
        ];
      }
    ];
  };

  services.cadvisor = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 8080;
  };

  services.nginx.statusPage = true;

  networking.firewall.interfaces.docker0.allowedTCPPorts = [9090];

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3002;
        domain = "grafana.dcard.pt";
        root_url = "https://grafana.dcard.pt/";
      };

      analytics.reporting_enabled = false;

      security.secret_key = "$__file{/var/lib/grafana/secret_key}";
      security.admin_password = "$__file{/var/lib/grafana/admin_password}";
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:9090";
          isDefault = true;
        }
      ];

      dashboards.settings.providers = [
        {
          name = "Maxwell";
          options.path = "/etc/grafana-dashboards";
        }
      ];
    };
  };

  environment.etc."grafana-dashboards/maxwell-overview.json".source =
    ./grafana-dashboards/maxwell-overview.json;
  environment.etc."grafana-dashboards/maxwell-storage.json".source =
    ./grafana-dashboards/maxwell-storage.json;
  environment.etc."grafana-dashboards/maxwell-services.json".source =
    ./grafana-dashboards/maxwell-services.json;
}
