let
  dcardLaptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMOK0uyFwBEoBHuqXsrWZOAMROsDYGjzwEUmrAhz5jfr dcard@laptop";
  maxwell = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKyvUMBe9p5JvMFDZtjDSEdBHLiPFXC0G/uuhweBwl3L";
in {
  "cloudflare/dcard.pt.age".publicKeys = [
    dcardLaptop
    maxwell
  ];
}
