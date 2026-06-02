{...}: {
  virtualisation = {
    docker = {
      enable = true;
      daemon.settings = {
        "metrics-addr" = "127.0.0.1:9323";
      };
    };

    oci-containers = {
      backend = "docker";
      containers.portainer = {
        image = "portainer/portainer-ce:latest";
        autoStart = true;
        ports = [
          "127.0.0.1:9443:9443"
        ];
        volumes = [
          "portainer_data:/data"
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
      };

      containers.uptime-kuma = {
        image = "louislam/uptime-kuma:2";
        autoStart = true;
        ports = [
          "127.0.0.1:3001:3001"
        ];
        volumes = [
          "uptime_kuma_data:/app/data"
        ];
        environment.TZ = "Europe/Lisbon";
      };
    };
  };

  users.users.dcard.extraGroups = ["docker"];
}
