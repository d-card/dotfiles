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

    };
  };

  users.users.dcard.extraGroups = ["docker"];
}
