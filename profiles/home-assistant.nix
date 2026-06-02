{...}: {
  system.activationScripts.homeAssistantContainerConfig.text = ''
        mkdir -p /var/lib/hass

        if [ -L /var/lib/hass/configuration.yaml ]; then
          rm /var/lib/hass/configuration.yaml
        fi

        if [ ! -e /var/lib/hass/configuration.yaml ]; then
          cat > /var/lib/hass/configuration.yaml <<'EOF'
    default_config: {}
    homeassistant:
      time_zone: Europe/Lisbon
    http:
      server_host: 127.0.0.1
      server_port: 8123
      trusted_proxies:
        - 127.0.0.1
      use_x_forwarded_for: true
    EOF
        fi
  '';

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:stable";
    autoStart = true;
    volumes = [
      "/var/lib/hass:/config"
      "/etc/localtime:/etc/localtime:ro"
      "/run/dbus:/run/dbus:ro"
    ];
    environment.TZ = "Europe/Lisbon";
    extraOptions = [
      "--network=host"
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
      "--pull=always"
    ];
  };

  systemd.services.docker-home-assistant.after = ["network-online.target"];
  systemd.services.docker-home-assistant.wants = ["network-online.target"];
}
