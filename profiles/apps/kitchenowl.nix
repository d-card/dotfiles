{
  config,
  pkgs,
  secrets,
  ...
}: let
in {

  system.activationScripts.kitchenowlSecrets.text = ''
    install -d -m 0750 /var/lib/kitchenowl

    if [ ! -e /var/lib/kitchenowl/kitchenowl.env ]; then
      printf 'JWT_SECRET_KEY=' > /var/lib/kitchenowl/kitchenowl.env
      ${pkgs.openssl}/bin/openssl rand -base64 48 >> /var/lib/kitchenowl/kitchenowl.env
    fi

    chmod 0600 /var/lib/kitchenowl/kitchenowl.env
  '';

  virtualisation.oci-containers.containers.kitchenowl = {
    image = "tombursch/kitchenowl:latest";
    autoStart = true;
    ports = ["127.0.0.1:3006:8080"];
    volumes = ["kitchenowl_data:/data"];
    environmentFiles = ["/var/lib/kitchenowl/kitchenowl.env"];
    environment = {
      FRONT_URL = "https://kitchenowl.dcard.pt";
      TZ = "Europe/Lisbon";
    };
  };

}
