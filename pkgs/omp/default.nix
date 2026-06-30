{ stdenv, fetchurl, patchelf, glibc, ... }:
stdenv.mkDerivation {
  pname = "omp";
  version = "16.2.8";

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v16.2.8/omp-linux-x64";
    hash = "sha256-GsM2bJMppwgo3QRr1w+yzT0ymBNz+zPfj4grA53kxCs=";
  };

  nativeBuildInputs = [ patchelf ];

  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/omp
    chmod +w $out/bin/omp
    patchelf --set-interpreter ${glibc}/lib/ld-linux-x86-64.so.2 $out/bin/omp
    chmod +x $out/bin/omp
  '';
}
