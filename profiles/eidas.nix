{pkgs, ...}: {
  # PC/SC smart card stack for the Cartão de Cidadão.
  # services.pcscd pulls in ccid (reader drivers + udev rules) automatically.
  services.pcscd.enable = true;

  environment.systemPackages = with pkgs; [
    pteid-mw
    pcsc-tools
    opensc # pkcs11-tool: module/reader diagnostics
  ];
}
