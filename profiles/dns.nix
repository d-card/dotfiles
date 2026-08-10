{...}: {
  services.adguardhome = {
    enable = true;
    host = "127.0.0.1";
    port = 3000;
    openFirewall = false;

    settings = {
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = false;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          name = "AdAway Default Blocklist";
          id = 2;
        }
        {
          enabled = false;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_48.txt";
          name = "HaGeZi's Pro Blocklist";
          id = 1780862685;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_27.txt";
          name = "OISD Blocklist Big";
          id = 1780862686;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt";
          name = "HaGeZi's Threat Intelligence Feeds";
          id = 1780862687;
        }
      ];

      user_rules = [
        "||valetudo.dcard.pt^$dnsrewrite=192.168.1.135"
      ];

      dns = {
        bind_hosts = ["0.0.0.0"];
        port = 53;
        upstream_dns = [
          "1.1.1.1"
          "1.0.0.1"
        ];
        bootstrap_dns = [
          "1.1.1.1"
          "1.0.0.1"
        ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };
}
