{ stdenv, fetchurl, ... }:
stdenv.mkDerivation {
  pname = "omp";
  version = "16.2.5";

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v16.2.5/omp-linux-x64";
    hash = "sha256-ST82Uo7KZ3rIE71C1aMpDwAl/0zU+U7bWpck3MQvAzY=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/omp
    chmod +x $out/bin/omp
  '';
}
