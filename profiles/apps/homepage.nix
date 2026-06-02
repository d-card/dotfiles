{pkgs, ...}: let
  yaml = pkgs.formats.yaml {};

  settings = yaml.generate "homepage-settings.yaml" {
    title = "Maxwell";
    theme = "dark";
    color = "slate";
    target = "_self";
    hideVersion = true;
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
          };
        }
        {
          AdGuard = {
            href = "https://adguard.dcard.pt";
            description = "LAN DNS and filtering";
            icon = "adguard-home";
          };
        }
        {
          Status = {
            href = "https://status.dcard.pt";
            description = "Uptime checks";
            icon = "uptime-kuma";
          };
        }
        {
          Grafana = {
            href = "https://grafana.dcard.pt";
            description = "Metrics dashboards";
            icon = "grafana";
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
          };
        }
        {
          Mealie = {
            href = "https://mealie.dcard.pt";
            description = "Recipes and meal planning";
            icon = "mealie";
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
          };
        }
        {
          "Stirling PDF" = {
            href = "https://pdf.dcard.pt";
            description = "PDF utilities";
            icon = "stirling-pdf";
          };
        }
        {
          PrivateBin = {
            href = "https://paste.dcard.pt";
            description = "Encrypted temporary pastes";
            icon = "privatebin";
          };
        }
        {
          ntfy = {
            href = "https://ntfy.dcard.pt";
            description = "Push notifications";
            icon = "ntfy";
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
in {
  system.activationScripts.homepageConfig.text = ''
    install -d -m 0755 /var/lib/homepage
    cp -f ${settings} /var/lib/homepage/settings.yaml
    cp -f ${services} /var/lib/homepage/services.yaml
    cp -f ${widgets} /var/lib/homepage/widgets.yaml
    cp -f ${bookmarks} /var/lib/homepage/bookmarks.yaml
  '';

  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:latest";
    autoStart = true;
    ports = ["127.0.0.1:3003:3000"];
    volumes = ["/var/lib/homepage:/app/config"];
    environment.HOMEPAGE_ALLOWED_HOSTS = "homepage.dcard.pt";
  };
}
