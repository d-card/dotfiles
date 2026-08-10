{
  stdenv,
  fetchurl,
  lib,
  inputs,
  autoPatchelfHook,
  libgcc,
  ...
}: stdenv.mkDerivation {
  pname = "netmuxd";
  version = "0.4.3";

  src = fetchurl {
    url = "https://github.com/jkcoxson/netmuxd/releases/download/v0.4.3/netmuxd-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "sha256-hbZZgoT8Y58qKCWERh0F4gkLeb3z7JSdKl5dPcZV3eQ=";
  };

  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [libgcc];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp netmuxd $out/bin/netmuxd
    chmod +x $out/bin/netmuxd
    runHook postInstall
  '';

  meta = {
    description = "Network/USB multiplexer for iOS devices (usbmuxd replacement)";
    homepage = "https://github.com/jkcoxson/netmuxd";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
