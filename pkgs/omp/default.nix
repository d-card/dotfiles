{ stdenv, fetchurl, patchelf, glibc, ... }:
stdenv.mkDerivation {
  pname = "omp";
  version = "18.1.11";

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v18.1.11/omp-linux-x64";
    hash = "sha256-Kyx4W7uv07Q/tgluSuY6A0LE2Aad4vh1qbduqZR8I4M=";
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
