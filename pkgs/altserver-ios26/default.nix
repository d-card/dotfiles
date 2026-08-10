{
  stdenv,
  python3,
  lib,
  inputs,
  ...
}: stdenv.mkDerivation {
  pname = "altserver-linux-ios26";
  version = "0.0.5-ios26";

  # Patched build of the ondrej-simon fork (iOS 26 code-signing fix).
  # Patch: libimobiledevice idevice.c network-device sockaddr handling —
  # the upstream code reads the Darwin sin_len/family layout
  # (conn_data[0]=len, conn_data[1]=family) but netmuxd serves a Linux
  # sockaddr_in (family at [0]). Without this fix, connecting to a
  # network (WiFi) device fails with "There was an error connecting to
  # the device." Build: ghcr.io/nyamisty/altserver_builder_alpine_amd64
  # with `make NO_USBMUXD_STUB=1 NO_UPNP_STUB=1`.
  src = ./AltServer-x86_64;

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = [python3];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp $src $out/bin/alt-server
    chmod +x $out/bin/alt-server

    # armconverter.com (default anisette server) is permanently down;
    # redirect to a working anisette-v3 server. Patch a copy in $out
    # (the nix store is read-only during build, so write via a temp file).
    python3 - <<PYEOF
    import pathlib, tempfile, os
    path = pathlib.Path("$out/bin/alt-server")
    data = bytearray(path.read_bytes())
    old = b"https://armconverter.com/anisette/irGb3Quww8zrhgqnzmrx"
    assert data.count(old) == 2, f"anisette URL pattern count {data.count(old)}"
    for _ in range(data.count(old)):
        i = data.find(old)
        data[i:i + len(old)] = b"https://ani.sidestore.io/".ljust(len(old), b"\x00")
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path))
    with os.fdopen(fd, "wb") as f:
        f.write(data)
    os.chmod(tmp, 0o755)
    os.replace(tmp, path)
    PYEOF
    runHook postInstall
  '';

  meta = {
    description = "AltServer-Linux fork with iOS 26 code signing fixes + WiFi device connect fix";
    homepage = "https://github.com/ondrej-simon/AltServer-Linux";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
  };
}
