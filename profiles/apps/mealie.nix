{...}: {
  virtualisation.oci-containers.containers.mealie = {
    image = "ghcr.io/mealie-recipes/mealie:v3.17.0";
    autoStart = true;
    ports = ["127.0.0.1:3006:9000"];
    volumes = ["mealie_data:/app/data"];
    environment = {
      ALLOW_SIGNUP = "false";
      BASE_URL = "https://mealie.dcard.pt";
      TZ = "Europe/Lisbon";
    };
  };
}
