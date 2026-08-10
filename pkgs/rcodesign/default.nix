{
  stdenv,
  fetchurl,
  lib,
  inputs,
  ...
}: stdenv.mkDerivation {
  pname = "rcodesign";
  version = "0.29.0";

  src = fetchurl {
    url = "https://github.com/indygreg/apple-platform-rs/releases/download/apple-codesign/0.29.0/apple-codesign-0.29.0-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "sha256-2+hc7djuQhe2TpoOTCrvkquLyqpB8gvemXgf8C5gAAI=";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r apple-codesign-*/rcodesign $out/bin/rcodesign
    chmod +x $out/bin/rcodesign
    runHook postInstall
  '';

  meta = {
    description = "Sign and notarize macOS/iOS apps from Linux";
    homepage = "https://github.com/indygreg/apple-platform-rs";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
