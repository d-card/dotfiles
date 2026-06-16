{
  hardware = {
    cpu.amd.updateMicrocode = true;
    graphics.enable = true;
  };

  boot.kernelModules = ["kvm-amd"];
}
