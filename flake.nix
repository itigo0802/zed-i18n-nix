{
  description = "Nix packaging for LI-NA/zed-i18n release binaries (Zed with community translations)";

  # 位置づけ: バイナリを Nix の derivation に「固定する」だけの薄いラッパ。
  # バイナリ本体は同梱せず GitHub Releases を fetchurl で参照する（再配布しない）。
  # 更新は `nix-update --flake zed-i18n`。CI（.github/workflows/update.yml）が
  # 週次で実行し、コミットする。利用側は `nix flake update zed-i18n` で追従する。
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (nixpkgs.legacyPackages.${system}));
    in
    {
      packages = forAllSystems (pkgs:
        let
          zed-i18n = pkgs.callPackage ./pkgs/zed-i18n.nix { };
        in
        {
          inherit zed-i18n;
          default = zed-i18n;
        });

      overlays.default = final: prev: {
        zed-i18n = final.callPackage ./pkgs/zed-i18n.nix { };
      };
    };
}
