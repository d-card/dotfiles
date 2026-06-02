{...}: {
  virtualisation.oci-containers.containers.it-tools = {
    image = "corentinth/it-tools:latest";
    autoStart = true;
    ports = ["127.0.0.1:3004:80"];
  };
}
