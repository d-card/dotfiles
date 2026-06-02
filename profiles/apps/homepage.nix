{pkgs, ...}: let
  yaml = pkgs.formats.yaml {};

  settings = yaml.generate "homepage-settings.yaml" {
    title = "Maxwell";
    description = "Home server";
    theme = "dark";
    color = "neutral";
    target = "_self";
    fullWidth = true;
    language = "en";
    headerStyle = "boxedWidgets";
    statusStyle = "dot";
    iconStyle = "theme";
    cardBlur = "xs";
    hideErrors = true;
    hideVersion = true;
    disableIndexing = true;
    layout = {
      Infrastructure = {
        style = "row";
        columns = 3;
      };
      Observability = {
        style = "row";
        columns = 4;
      };
      Home = {
        style = "row";
        columns = 2;
      };
      Tools = {
        style = "row";
        columns = 4;
      };
    };
  };

  services = yaml.generate "homepage-services.yaml" [
    {
      Infrastructure = [
        {
          Portainer = {
            href = "https://portainer.dcard.pt";
            description = "Container management";
            icon = "portainer";
            siteMonitor = "https://portainer.dcard.pt";
          };
        }
        {
          AdGuard = {
            href = "https://adguard.dcard.pt";
            description = "LAN DNS and filtering";
            icon = "adguard-home";
            siteMonitor = "https://adguard.dcard.pt";
          };
        }
        {
          Status = {
            href = "https://status.dcard.pt";
            description = "Uptime checks";
            icon = "uptime-kuma";
            siteMonitor = "https://status.dcard.pt/status/maxwell";
          };
        }
      ];
    }
    {
      Observability = [
        {
          Grafana = {
            href = "https://grafana.dcard.pt";
            description = "Metrics dashboards";
            icon = "grafana";
            siteMonitor = "https://grafana.dcard.pt";
          };
        }
        {
          "Service Status" = {
            href = "https://status.dcard.pt/status/maxwell";
            description = "Public service health";
            icon = "uptime-kuma";
            siteMonitor = "https://status.dcard.pt/status/maxwell";
          };
        }
        {
          Logs = {
            href = "https://grafana.dcard.pt/d/maxwell-logs/maxwell-logs";
            description = "Loki service logs";
            icon = "grafana";
            siteMonitor = "https://grafana.dcard.pt";
          };
        }
        {
          Storage = {
            href = "https://grafana.dcard.pt/d/maxwell-storage/maxwell-storage";
            description = "Disk usage trends";
            icon = "grafana";
            siteMonitor = "https://grafana.dcard.pt";
          };
        }
      ];
    }
    {
      Home = [
        {
          "Home Assistant" = {
            href = "https://home-assistant.dcard.pt";
            description = "Home automation";
            icon = "home-assistant";
            siteMonitor = "https://home-assistant.dcard.pt";
          };
        }
        {
          Mealie = {
            href = "https://mealie.dcard.pt";
            description = "Recipes and meal planning";
            icon = "mealie";
            siteMonitor = "https://mealie.dcard.pt";
          };
        }
      ];
    }
    {
      Tools = [
        {
          "IT Tools" = {
            href = "https://tools.dcard.pt";
            description = "Useful browser tools";
            icon = "it-tools";
            siteMonitor = "https://tools.dcard.pt";
          };
        }
        {
          "Stirling PDF" = {
            href = "https://pdf.dcard.pt";
            description = "PDF utilities";
            icon = "stirling-pdf";
            siteMonitor = "https://pdf.dcard.pt";
          };
        }
        {
          PrivateBin = {
            href = "https://paste.dcard.pt";
            description = "Encrypted temporary pastes";
            icon = "privatebin";
            siteMonitor = "https://paste.dcard.pt";
          };
        }
        {
          ntfy = {
            href = "https://ntfy.dcard.pt";
            description = "Push notifications";
            icon = "ntfy";
            siteMonitor = "https://ntfy.dcard.pt";
          };
        }
      ];
    }
  ];

  widgets = yaml.generate "homepage-widgets.yaml" [
    {
      resources = {
        cpu = true;
        memory = true;
        disk = "/";
      };
    }
    {
      search = {
        provider = "duckduckgo";
        target = "_blank";
      };
    }
  ];

  bookmarks = yaml.generate "homepage-bookmarks.yaml" [
    {
      Dashboards = [
        {
          Overview = [
            {
              abbr = "GO";
              href = "https://grafana.dcard.pt/d/maxwell-overview/maxwell-overview";
            }
          ];
        }
        {
          Logs = [
            {
              abbr = "GL";
              href = "https://grafana.dcard.pt/d/maxwell-logs/maxwell-logs";
            }
          ];
        }
        {
          Storage = [
            {
              abbr = "GS";
              href = "https://grafana.dcard.pt/d/maxwell-storage/maxwell-storage";
            }
          ];
        }
      ];
    }
  ];

  customCss = pkgs.writeText "homepage-custom.css" ''
    :root {
      --maxwell-bg: #0e1116;
      --maxwell-panel: rgba(25, 30, 37, 0.82);
      --maxwell-panel-strong: rgba(31, 38, 47, 0.96);
      --maxwell-border: rgba(255, 255, 255, 0.1);
      --maxwell-border-strong: rgba(255, 255, 255, 0.18);
      --maxwell-muted: rgba(255, 255, 255, 0.58);
      --maxwell-text: rgba(255, 255, 255, 0.9);
      --maxwell-accent: #5ca877;
      --maxwell-accent-2: #6f9ed8;
      --maxwell-warn: #d8a85f;
    }

    html {
      background: var(--maxwell-bg);
    }

    body {
      background:
        radial-gradient(circle at 18% 0%, rgba(92, 168, 119, 0.18), transparent 26rem),
        radial-gradient(circle at 88% 8%, rgba(111, 158, 216, 0.14), transparent 28rem),
        linear-gradient(135deg, rgba(17, 20, 26, 0.99), rgba(10, 12, 16, 0.99)),
        var(--maxwell-bg);
      color: var(--maxwell-text);
    }

    #page_container {
      max-width: 1500px;
      padding-top: 1.25rem;
    }

    #inner_wrapper {
      gap: 1.35rem;
    }

    header,
    #information-widgets {
      position: relative;
      z-index: 1;
    }

    header::after {
      content: "LAN services, automation, telemetry";
      display: block;
      margin-top: 0.35rem;
      color: var(--maxwell-muted);
      font-size: 0.95rem;
      letter-spacing: 0;
    }

    #widgets-wrap {
      gap: 0.85rem;
    }

    #information-widgets > div,
    .service-card,
    .bookmark {
      border: 1px solid var(--maxwell-border);
      box-shadow: 0 18px 45px rgba(0, 0, 0, 0.26);
      backdrop-filter: blur(14px);
    }

    .service-card,
    .bookmark {
      background:
        linear-gradient(180deg, rgba(255, 255, 255, 0.035), transparent),
        var(--maxwell-panel);
      transition:
        background 150ms ease,
        border-color 150ms ease,
        transform 150ms ease,
        box-shadow 150ms ease;
    }

    .service-card:hover,
    .bookmark:hover {
      background:
        linear-gradient(180deg, rgba(255, 255, 255, 0.055), transparent),
        var(--maxwell-panel-strong);
      border-color: var(--maxwell-border-strong);
      box-shadow: 0 22px 55px rgba(0, 0, 0, 0.34);
      transform: translateY(-2px);
    }

    .service-card {
      min-height: 7.25rem;
    }

    .service-card::before,
    .bookmark::before {
      content: "";
      display: block;
      width: 2.6rem;
      height: 0.18rem;
      margin-bottom: 0.85rem;
      border-radius: 999px;
      background: linear-gradient(90deg, var(--maxwell-accent), var(--maxwell-accent-2));
    }

    .service-card .description,
    .service-card p,
    .bookmark-description {
      color: var(--maxwell-muted);
    }

    .service-name,
    .service-title-text,
    .bookmark-name {
      font-weight: 650;
    }

    .service-tags span,
    .service-status {
      border-radius: 999px;
    }

    .services-group .text-theme-800,
    .services-group .dark\:text-theme-200,
    .bookmark-group-name {
      letter-spacing: 0;
    }

    .services-group > div:first-child,
    .bookmark-group-name {
      color: rgba(255, 255, 255, 0.86);
      font-weight: 650;
    }

    .services-group > div:first-child::before,
    .bookmark-group-name::before {
      content: "";
      display: inline-block;
      width: 0.55rem;
      height: 0.55rem;
      margin-right: 0.55rem;
      border-radius: 999px;
      background: linear-gradient(135deg, var(--maxwell-accent), var(--maxwell-accent-2));
      vertical-align: 0.05rem;
    }

    #information-widgets > div {
      background: rgba(20, 24, 30, 0.76);
    }

    .resource-usage {
      color: var(--maxwell-muted);
    }

    .resource-icon {
      color: var(--maxwell-accent);
    }

    .bookmark-icon {
      background: rgba(92, 168, 119, 0.14);
      border: 1px solid rgba(92, 168, 119, 0.18);
    }

    input,
    .search-container input {
      background: rgba(14, 17, 22, 0.72) !important;
      border: 1px solid var(--maxwell-border) !important;
    }

    @media (max-width: 768px) {
      #page_container {
        padding-inline: 0.85rem;
      }

      header::after {
        font-size: 0.85rem;
      }

      .service-card {
        min-height: 6.5rem;
      }
    }
  '';
in {
  system.activationScripts.homepageConfig.text = ''
    install -d -m 0755 /var/lib/homepage
    cp -f ${settings} /var/lib/homepage/settings.yaml
    cp -f ${services} /var/lib/homepage/services.yaml
    cp -f ${widgets} /var/lib/homepage/widgets.yaml
    cp -f ${bookmarks} /var/lib/homepage/bookmarks.yaml
    cp -f ${customCss} /var/lib/homepage/custom.css
  '';

  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:latest";
    autoStart = true;
    ports = ["127.0.0.1:3003:3000"];
    volumes = ["/var/lib/homepage:/app/config"];
    environment.HOMEPAGE_ALLOWED_HOSTS = "homepage.dcard.pt";
  };
}
