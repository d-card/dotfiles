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

  alertRules = pkgs.writeText "maxwell-alerts.yml" ''
    groups:
      - name: maxwell-health
        rules:
          - alert: MaxwellTargetDown
            expr: up == 0
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "{{ $labels.job }} target is down"
              description: "{{ $labels.instance }} / {{ $labels.target }} has been unreachable for 5 minutes."

          - alert: MaxwellFilesystemAlmostFull
            expr: 100 - (node_filesystem_avail_bytes{fstype!~"tmpfs|devtmpfs|overlay|squashfs|proc|sysfs|cgroup2"} * 100 / node_filesystem_size_bytes{fstype!~"tmpfs|devtmpfs|overlay|squashfs|proc|sysfs|cgroup2"}) > 85
            for: 15m
            labels:
              severity: warning
            annotations:
              summary: "Filesystem {{ $labels.mountpoint }} is almost full"
              description: "{{ $labels.mountpoint }} on {{ $labels.instance }} is above 85% used."

          - alert: MaxwellFilesystemWillFillSoon
            expr: (predict_linear(node_filesystem_avail_bytes{fstype!~"tmpfs|devtmpfs|overlay|squashfs|proc|sysfs|cgroup2",mountpoint!~"/boot|/nix/store"}[6h], 7 * 24 * 3600) < 0) and (node_filesystem_avail_bytes{fstype!~"tmpfs|devtmpfs|overlay|squashfs|proc|sysfs|cgroup2",mountpoint!~"/boot|/nix/store"} * 100 / node_filesystem_size_bytes{fstype!~"tmpfs|devtmpfs|overlay|squashfs|proc|sysfs|cgroup2",mountpoint!~"/boot|/nix/store"} < 25)
            for: 30m
            labels:
              severity: warning
            annotations:
              summary: "Filesystem {{ $labels.mountpoint }} may fill within 7 days"
              description: "{{ $labels.mountpoint }} on {{ $labels.instance }} is trending toward full."

          - alert: MaxwellInodesAlmostFull
            expr: 100 - (node_filesystem_files_free{fstype!~"tmpfs|devtmpfs|overlay|squashfs|proc|sysfs|cgroup2"} * 100 / node_filesystem_files{fstype!~"tmpfs|devtmpfs|overlay|squashfs|proc|sysfs|cgroup2"}) > 85
            for: 15m
            labels:
              severity: warning
            annotations:
              summary: "Filesystem {{ $labels.mountpoint }} is low on inodes"
              description: "{{ $labels.mountpoint }} on {{ $labels.instance }} is above 85% inode usage."

          - alert: MaxwellSmartStatusFailed
            expr: smartctl_device_smart_status == 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "SMART health failed for {{ $labels.device }}"
              description: "{{ $labels.device }} on {{ $labels.instance }} reports failing SMART health."

          - alert: MaxwellHighTemperature
            expr: smartctl_device_temperature{temperature_type="current"} > 55
            for: 15m
            labels:
              severity: warning
            annotations:
              summary: "{{ $labels.device }} temperature is high"
              description: "{{ $labels.device }} on {{ $labels.instance }} is above 55C."

          - alert: MaxwellSystemdUnitFailed
            expr: node_systemd_unit_state{state="failed"} > 0
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "Systemd unit failed: {{ $labels.name }}"
              description: "{{ $labels.name }} is failed on {{ $labels.instance }}."
  '';
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
    ruleFiles = [alertRules];

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
              "https://homepage.dcard.pt"
              "https://tools.dcard.pt"
              "https://pdf.dcard.pt"
              "https://kitchenowl.dcard.pt"
              "https://ntfy.dcard.pt"
              "https://paste.dcard.pt"
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

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = 3100;
        grpc_listen_port = 9096;
      };

      common = {
        path_prefix = "/var/lib/loki";
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
        storage.filesystem = {
          chunks_directory = "/var/lib/loki/chunks";
          rules_directory = "/var/lib/loki/rules";
        };
      };

      schema_config.configs = [
        {
          from = "2026-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      limits_config = {
        retention_period = "14d";
        allow_structured_metadata = false;
      };

      compactor = {
        working_directory = "/var/lib/loki/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };
    };
  };

  services.alloy = {
    enable = true;
    extraFlags = [
      "--disable-reporting"
      "--server.http.listen-addr=127.0.0.1:12345"
    ];
  };

  environment.etc."alloy/config.alloy".text = ''
    loki.write "local" {
      endpoint {
        url = "http://127.0.0.1:3100/loki/api/v1/push"
      }
    }

    loki.relabel "journal" {
      forward_to = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }

      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "level"
      }

      rule {
        source_labels = ["__journal_syslog_identifier"]
        target_label  = "syslog_identifier"
      }
    }

    loki.source.journal "system" {
      max_age       = "12h"
      relabel_rules = loki.relabel.journal.rules
      labels        = {
        job  = "systemd-journal",
        host = "maxwell",
      }
      forward_to    = [loki.write.local.receiver]
    }
  '';

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3002;
        domain = "grafana.dcard.pt";
        root_url = "https://grafana.dcard.pt/";
      };

      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
        check_for_plugin_updates = false;
      };

      security.secret_key = "$__file{/var/lib/grafana/secret_key}";
      security.admin_password = "$__file{/var/lib/grafana/admin_password}";
    };

    provision = {
      enable = true;
      datasources.settings = {
        deleteDatasources = [
          {
            name = "Loki";
            orgId = 1;
          }
        ];

        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
            isDefault = true;
          }
          {
            name = "Loki";
            uid = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://127.0.0.1:3100";
          }
        ];
      };

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
  environment.etc."grafana-dashboards/maxwell-logs.json".source =
    ./grafana-dashboards/maxwell-logs.json;
}
