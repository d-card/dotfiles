{pkgs, ...}: {
  # PC/SC smart card stack for the Cartão de Cidadão.
  # services.pcscd pulls in ccid (reader drivers + udev rules) automatically.
  services.pcscd.enable = true;

  # The official Autenticação.gov app (AMA) is distributed as a Flatpak.
  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    pteid-mw
  ];
}
