{
  config,
  profiles,
  secrets,
  ...
}: {
  imports = [
    profiles.secrets
  ];

  age.secrets.cloudflareToken.file = secrets."cloudflare/dcard.pt.age".file;

  security.acme = {
    acceptTerms = true;
    defaults.email = "me@dcard.pt";
  };
}
