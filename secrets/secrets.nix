let
  schrodinger = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMOK0uyFwBEoBHuqXsrWZOAMROsDYGjzwEUmrAhz5jfr dcard@schrodinger";
  maxwell = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyvUMBe9p5JvMFDZtjDSEdBHLiPFXC0G/uuhweBwl3L";
in {
  "cloudflare/dcard.pt.age".publicKeys = [
    schrodinger
    maxwell
  ];
  "schrodinger-password.age".publicKeys = [
    schrodinger
    maxwell
  ];
}
