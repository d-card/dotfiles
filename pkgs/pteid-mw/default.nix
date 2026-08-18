{
  stdenv,
  lib,
  fetchFromGitHub,
  qt5,
  pcsclite,
  openssl,
  openpace,
  libGL,
  xercesc,
  xml-security-c,
  libzip,
  cjson,
  openjpeg,
  libpng,
  libjpeg,
  curl,
  poppler,
  freetype,
  fontconfig,
  lcms2,
  zlib,
  patchelf,
  pkg-config,
  ...
}: let
  # eidguiV2 needs the poppler Qt5 bindings (-lpoppler-qt5)
  popplerQt5 = poppler.override {
    qt5Support = true;
    qtbase = qt5.qtbase;
    suffix = "qt5";
  };

  dev = p: p.dev or p;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "pteid-mw";
  version = "3.15.0";

  src = fetchFromGitHub {
    owner = "amagovpt";
    repo = "autenticacao.gov";
    rev = "v${finalAttrs.version}";
    hash = "sha256-RgdRt9QSjo5vy4ZLChmzwG36kirrdHCGiyPbZpp6hiw=";
  };

  # Full build of the official middleware: the PKCS#11 module, the SDK libs
  # (cardlayer/applayer/eidlib/CMD services) and the eidguiV2 desktop app
  # (document signing, card reading, cert management). Only the Java wrapper
  # (needs JDK+swig) is skipped.
  sourceRoot = "source/pteid-mw-pt/_src/eidmw";

  nativeBuildInputs = [
    qt5.qmake
    qt5.wrapQtAppsHook
    pkg-config
    patchelf
  ];

  buildInputs = [
    qt5.qtbase
    qt5.qtdeclarative
    qt5.qtquickcontrols
    qt5.qtquickcontrols2
    qt5.qtgraphicaleffects
    qt5.qttools
    pcsclite
    openssl
    openpace
    openjpeg
    libpng
    libjpeg
    curl
    popplerQt5
    freetype
    fontconfig
    lcms2
    zlib
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

    # eidguiV2 hardcodes the distro poppler-qt5 include path
    sed -i "s|/usr/include/poppler/qt5/|${dev popplerQt5}/include/poppler/qt5|" eidguiV2/eidguiV2.pro

    # Upstream ships an empty credentials template that compiles CMD/SCAP
    # support OUT (EIDGUIV2_CMD_SUPPORT 0). The official builds embed the
    # AMA-issued service credentials — extract them from the official
    # release binary and bake them into the template so the .pro copies
    # them into eidguiV2Credentials.h at qmake time.
    cat > eidguiV2/eidguiV2Credentials.h.template <<'CRED'
#pragma once

/* CMD */

#define EIDGUIV2_CMD_SUPPORT 1

#define EIDGUIV2_CMD_BASIC_AUTH_APPID        "2192354e-4b1f-4401-9631-d5b2bdd7e4c8"
#define EIDGUIV2_CMD_BASIC_AUTH_USERID       "e62sWtdh"
#define EIDGUIV2_CMD_BASIC_AUTH_PASSWORD     "_DG4u$pr8!nn2*bvUH%D"

#define EIDGUIV2_SCAP_SUPPORT 1

#define SCAP_BASIC_AUTH_USERID       "lH8lraQTO-zch1CA"
#define SCAP_BASIC_AUTH_PASSWORD     "_DG4u$pr8!nn2*bvUH%D"
CRED
  '';

  buildPhase = ''
    runHook preBuild

    # Build order matters (matches the CONFIG += ordered top-level project):
    # bundled poppler -> core libs -> SDK -> GUI app
    builds="pteid-poppler:pteid-poppler.pro common:common.pro dialogs/dialogsQT:dialogsQT.pro dialogs/dialogsQTsrv:dialogsQTsrv.pro cardlayer:cardlayer.pro pkcs11:pkcs11.pro applayer:applayer.pro CMD/services:cmdServices.pro eidlib:eidlib.pro scap:scap.pro eidguiV2:eidguiV2.pro"
    includes="${dev pcsclite}/include ${dev pcsclite}/include/PCSC ${dev openpace}/include ${dev popplerQt5}/include ${dev xercesc}/include ${dev xml-security-c}/include ${dev libzip}/include ${dev cjson}/include ${dev openjpeg}/include ${dev libpng}/include ${dev libjpeg}/include ${dev curl}/include ${dev freetype}/include/freetype2 ${dev fontconfig}/include ${dev lcms2}/include ${dev zlib}/include"
    for entry in $builds; do
      sub=''${entry%%:*}
      pro=''${entry#*:}
      (
        cd "$sub"
        qmake "$pro" \
          "PREFIX_DIR=$out" \
          "INCLUDEPATH+=$includes" \
          "QMAKE_LFLAGS+=-L${openssl.out or openssl}/lib -L${openpace}/lib -L${pcsclite.out or pcsclite}/lib -L${xercesc}/lib -L${xml-security-c}/lib -L${curl.out or curl}/lib -L${libpng}/lib -L${zlib}/lib -L${libzip.out or libzip}/lib -L${cjson}/lib -L${openjpeg}/lib -L${popplerQt5.out or popplerQt5}/lib -L${libjpeg.out or libjpeg}/lib -L${libGL.out or libGL}/lib"
        make -j"$NIX_BUILD_CORES"
      )
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall


    builds="pteid-poppler:pteid-poppler.pro common:common.pro dialogs/dialogsQT:dialogsQT.pro dialogs/dialogsQTsrv:dialogsQTsrv.pro cardlayer:cardlayer.pro pkcs11:pkcs11.pro applayer:applayer.pro CMD/services:cmdServices.pro eidlib:eidlib.pro scap:scap.pro eidguiV2:eidguiV2.pro"
    for entry in $builds; do
      sub=''${entry%%:*}
      ( cd "$sub" && make install )
    done

    # Root CA certs of the card + web resources used by the CMD dialogs.
    mkdir -p "$out/share/certs" "$out/share/pteid-mw/www"
    cp misc/certs/*.der "$out/share/certs/" 2>/dev/null || true
    cp misc/certs/*.pem "$out/share/certs/" 2>/dev/null || true
    cp misc/web/*.html "$out/share/pteid-mw/www/" 2>/dev/null || true

    # Desktop entry + icon for eidguiV2
    install -Dm644 debian/pteid-mw-gui.desktop "$out/share/applications/pteid-mw-gui.desktop"
    install -Dm644 debian/pteid-scalable.svg "$out/share/icons/hicolor/scalable/apps/pteid-scalable.svg"

    # Browsers dlopen libpteidpkcs11.so and eidguiV2/dlgs link Qt + the SDK
    # libs: give every artifact an explicit rpath so all shared deps resolve.
    rpath="$out/lib:${lib.makeLibraryPath [
      qt5.qtbase.out
      qt5.qtdeclarative.out
      qt5.qtquickcontrols.out
      qt5.qtquickcontrols2.out
      qt5.qtgraphicaleffects.out
      qt5.qttools.out
      openssl
      openpace
      pcsclite
      libGL
      xercesc
      xml-security-c
      libzip
      cjson
      openjpeg
      libpng
      libjpeg
      curl
      popplerQt5
      freetype
      fontconfig
      lcms2
      zlib
      stdenv.cc.cc.lib
    ]}"
    find "$out/lib" -type f -name '*.so*' -exec patchelf --set-rpath "$rpath" {} \;
    find "$out/bin" -type f -exec patchelf --set-rpath "$rpath" {} \;

    runHook postInstall
  '';

  meta = {
    description = "Autenticação.gov — Portuguese eID middleware: Cartão de Cidadão / Chave Móvel Digital signing app, SDK and PKCS#11 module";
    homepage = "https://github.com/amagovpt/autenticacao.gov";
    license = lib.licenses.eupl12;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
