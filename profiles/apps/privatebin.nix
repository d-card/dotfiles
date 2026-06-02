{...}: {
  virtualisation.oci-containers.containers.privatebin = {
    image = "privatebin/nginx-fpm-alpine:latest";
    autoStart = true;
    ports = ["127.0.0.1:3008:8080"];
    volumes = ["privatebin_data:/srv/data"];
  };
}
