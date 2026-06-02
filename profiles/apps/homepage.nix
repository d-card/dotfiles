{pkgs, ...}: let
  yaml = pkgs.formats.yaml {};

  settings = yaml.generate "homepage-settings.yaml" {
    title = "Maxwell";
    description = "Home server";
    theme = "dark";
    color = "neutral";
    target = "_self";
    fullWidth = true;
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
        {
          Grafana = {
            href = "https://grafana.dcard.pt";
            description = "Metrics dashboards";
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

  bookmarks = yaml.generate "homepage-bookmarks.yaml" [];

  customCss = pkgs.writeText "homepage-custom.css" ''
    body {
      background:
        linear-gradient(135deg, rgba(22, 24, 29, 0.96), rgba(13, 15, 19, 0.98)),
        #111318;
    }

    #page_container {
      max-width: 1500px;
    }

    #information-widgets > div,
    .service-card {
      border: 1px solid rgba(255, 255, 255, 0.08);
      box-shadow: 0 18px 45px rgba(0, 0, 0, 0.22);
    }

    .service-card {
      background: rgba(28, 31, 38, 0.72);
    }

    .service-card:hover {
      background: rgba(37, 41, 50, 0.9);
      border-color: rgba(255, 255, 255, 0.16);
      transform: translateY(-1px);
    }

    .service-card .description,
    .service-card p {
      color: rgba(255, 255, 255, 0.58);
    }

    .services-group .text-theme-800,
    .services-group .dark\:text-theme-200 {
      letter-spacing: 0;
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
