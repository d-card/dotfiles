{...}: {
  virtualisation.oci-containers.containers.ntfy = {
    image = "binwiederhier/ntfy:latest";
    autoStart = true;
    cmd = [
      "serve"
      "--cache-file"
      "/var/cache/ntfy/cache.db"
      "--behind-proxy"
    ];
    ports = ["127.0.0.1:3007:80"];
    volumes = [
      "ntfy_cache:/var/cache/ntfy"
      "ntfy_data:/var/lib/ntfy"
    ];
    environment.TZ = "Europe/Lisbon";
  };
}
