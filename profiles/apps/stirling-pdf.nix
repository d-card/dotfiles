{...}: {
  virtualisation.oci-containers.containers.stirling-pdf = {
    image = "stirlingtools/stirling-pdf:latest";
    autoStart = true;
    ports = ["127.0.0.1:3005:8080"];
    volumes = ["stirling_pdf_data:/configs"];
    environment = {
      DISABLE_ADDITIONAL_FEATURES = "false";
      SECURITY_ENABLELOGIN = "false";
    };
  };
}
