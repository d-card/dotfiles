{
  stdenv,
  lib,
  fetchFromGitHub,
  qt5,
  pcsclite,
  openssl,
  openpace,
  libGL,
  patchelf,
  ...
}: stdenv.mkDerivation (finalAttrs: {
  pname = "pteid-mw";
  version = "3.15.0";

  src = fetchFromGitHub {
    owner = "amagovpt";
    repo = "autenticacao.gov";
    rev = "v${finalAttrs.version}";
    hash = "sha256-RgdRt9QSjo5vy4ZLChmzwG36kirrdHCGiyPbZpp6hiw=";
  };

  # The source tree contains the middleware plus the SDK/GUI. Only the
  # components required for browser authentication are built here:
  #   common        -> libpteidcommon
  #   dialogsQT     -> libpteiddialogsQT (spawns the PIN dialog server)
  #   dialogsQTsrv  -> pteiddialogsQTsrv (Qt5 PIN dialog)
  #   cardlayer     -> libpteidcardlayer (talks to the card via PC/SC + openpace)
  #   pkcs11        -> libpteidpkcs11 (the module browsers load)
  # PDF signing (pteid-poppler/applayer), eidguiV2 and the SDK are skipped.
  sourceRoot = "source/pteid-mw-pt/_src/eidmw";

  nativeBuildInputs = [
    qt5.qmake
    qt5.wrapQtAppsHook
    patchelf
  ];

  buildInputs = [
    qt5.qtbase
    pcsclite
    openssl
    openpace
  ];

  patches = [
    ./gcc15-cstdint.patch
  ];

  prePatch = ''
    # Upstream ships some files with CRLF line endings; normalize so the
    # cstdint patch applies cleanly.
    find . -type f \( -name '*.cpp' -o -name '*.h' -o -name '*.pro' -o -name '*.mak' \) -exec sed -i 's/\r$//' {} +
  '';

  postPatch = ''
    # Bake the store paths into the runtime defaults for the certs/web dirs.
    sed -i \
      -e 's|WDIRSEP L"usr" WDIRSEP L"local" WDIRSEP L"share" WDIRSEP L"certs" WDIRSEP|L"'"$out"'/share/certs/"|' \
      -e 's|WDIRSEP L"usr" WDIRSEP L"local" WDIRSEP L"share" WDIRSEP L"certs_test" WDIRSEP|L"'"$out"'/share/certs_test/"|' \
      -e 's|WDIRSEP L"usr" WDIRSEP L"local" WDIRSEP L"share" WDIRSEP L"pteid-mw" WDIRSEP L"www"|L"'"$out"'/share/pteid-mw/www/"|' \
      common/ConfigCommon.cpp
  '';

  buildPhase = ''
    runHook preBuild

    subs="common dialogs/dialogsQT dialogs/dialogsQTsrv cardlayer pkcs11"
    for sub in $subs; do
      (
        cd "$sub"
        qmake "$(basename "$sub").pro" \
          "PREFIX_DIR=$out" \
          "INCLUDEPATH+=${pcsclite.dev}/include ${pcsclite.dev}/include/PCSC ${openpace}/include"
        make -j"$NIX_BUILD_CORES"
      )
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for sub in common dialogs/dialogsQT dialogs/dialogsQTsrv cardlayer pkcs11; do
      ( cd "$sub" && make install )
    done

    # Root CA certs of the card, used for certificate chain validation.
    mkdir -p "$out/share/certs"
    cp misc/certs/*.der "$out/share/certs/" 2>/dev/null || true
    cp misc/certs/*.pem "$out/share/certs/" 2>/dev/null || true

    # Browsers dlopen libpteidpkcs11.so and the dialog server links Qt:
    # give every artifact an explicit rpath so all shared deps (pteid libs,
    # Qt, OpenSSL, openpace, PC/SC, libGL, libstdc++) resolve from the store.
    rpath="$out/lib:${lib.makeLibraryPath [ qt5.qtbase.out openssl openpace pcsclite libGL stdenv.cc.cc.lib ]}"
    find "$out/lib" -type f -name '*.so*' -exec patchelf --set-rpath "$rpath" {} \;
    find "$out/bin" -type f -exec patchelf --set-rpath "$rpath" {} \;

    runHook postInstall
  '';

  meta = {
    description = "Portuguese eID middleware (Cartão de Cidadão / Chave Móvel Digital) — PKCS#11 browser authentication module";
    homepage = "https://github.com/amagovpt/autenticacao.gov";
    license = lib.licenses.eupl12;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
