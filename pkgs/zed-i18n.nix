# LI-NA/zed-i18n の Linux x86_64 ビルド（日本語UI入りの Zed）を NixOS で動かす。
# 配布物は zed.app/{bin,libexec,lib,share} という AppImage 相当のレイアウトで、
# bin/zed（ランチャ）が隣の libexec/zed-editor を探す。その相対配置を保ったまま
# $out/lib/zed に置き、NEEDED は autoPatchelf、dlopen される lib は wrapper で補う。
#
# ライセンス: このファイルは Zed / zed-i18n のバイナリを再配布しない
# （fetchurl で GitHub Releases を参照するだけ）。Zed 本体は GPL-3.0。
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  nodejs,
  bubblewrap,
  alsa-lib,
  glib,
  libxcb,
  libxkbcommon,
  libx11,
  libGL,
  vulkan-loader,
  wayland,
  fontconfig,
  freetype,
  openssl,
  nix-update-script,
}:

let
  # nixpkgs の zed-editor が postFixup で rpath に入れているのと同じ系統。
  # wgpu / フォント / TLS は dlopen されるので LD_LIBRARY_PATH で渡す。
  dlopenLibs = [
    libGL
    vulkan-loader
    wayland
    fontconfig
    freetype
    openssl
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zed-i18n";
  version = "1.27.0-i18n.1";

  src = fetchurl {
    url = "https://github.com/LI-NA/zed-i18n/releases/download/v${finalAttrs.version}/zed-i18n-linux-x86_64.tar.gz";
    hash = "sha256-l06imSu+v+8w8OqISJD//7UAsQ7RGh5astb/CsVpqWs=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    glib
    alsa-lib
    libxcb
    libxkbcommon
    libx11
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  # アーカイブのトップレベルが zed.app/ 1つだけなので、stdenv が自動で
  # その中へ cd してしまう。展開ディレクトリに留まって zed.app/ を丸ごと使う。
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/zed $out/bin
    cp -r zed.app/. $out/lib/zed/
    chmod +x $out/lib/zed/bin/zed $out/lib/zed/libexec/zed-editor

    makeWrapper $out/lib/zed/bin/zed $out/bin/zed-i18n \
      --prefix LD_LIBRARY_PATH : "$out/lib/zed/lib:${lib.makeLibraryPath dlopenLibs}" \
      --suffix PATH : "${lib.makeBinPath [ nodejs bubblewrap ]}" \
      --set ZED_UPDATE_EXPLANATION "Zed is managed by Nix; auto-update is disabled." \
      --set-default ZED_ALLOW_EMULATED_GPU "1"

    # デスクトップエントリ: bin/zed は公開しないので Exec/TryExec を zed-i18n に直す
    install -Dm644 $out/lib/zed/share/applications/dev.zed-i18n.Zed.desktop \
      $out/share/applications/dev.zed-i18n.Zed.desktop
    sed -i -e 's|^Exec=zed|Exec=zed-i18n|' -e 's|^TryExec=zed$|TryExec=zed-i18n|' \
      $out/share/applications/dev.zed-i18n.Zed.desktop

    install -Dm644 $out/lib/zed/share/icons/hicolor/512x512/apps/zed.png \
      $out/share/icons/hicolor/512x512/apps/zed.png

    runHook postInstall
  '';

  meta = {
    description = "Zed editor with community translations (LI-NA/zed-i18n)";
    homepage = "https://github.com/LI-NA/zed-i18n";
    # 上流 Zed 本体のライセンス。配布バイナリは zed-i18n によるビルド。
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "zed-i18n";
  };

  # nix-update 用。上流のタグは v1.27.0-i18n.1 の形なのでそのまま version にする。
  # nix-update はタグから version を、releases の tar.gz から hash を更新する。
  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version-regex" "^v([0-9]+\\.[0-9]+\\.[0-9]+-i18n\\.[0-9]+)$" ];
  };
})
