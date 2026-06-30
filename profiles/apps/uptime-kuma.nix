{...}: {
  virtualisation.oci-containers.containers.uptime-kuma = {
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
}
