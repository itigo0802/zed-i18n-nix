# zed-i18n-nix

[LI-NA/zed-i18n](https://github.com/LI-NA/zed-i18n) が GitHub Releases で配布している
**Zed のローカライズ版バイナリ**を、Nix の derivation に固定する薄い flake。

上流 Zed は日本語 UI を持たないため、翻訳を当てた再ビルドを使う。

## 何をするか / しないか

- する: リリースの `zed-i18n-linux-x86_64.tar.gz` を `fetchurl` で参照し、
  Nix から使えるパッケージとして公開する（`packages.<system>.zed-i18n`）。
- **しない: バイナリを同梱・再配布しない。** 取得先は常に上流のリリース。
- 更新は [`nix-update`](https://github.com/Mic92/nix-update) で行う。
  `.github/workflows/update.yml` が週次で version と hash を進める。

## 使い方

```nix
{
  inputs.zed-i18n.url = "github:itigo0802/zed-i18n-nix";

  # home-manager などで
  #   package = inputs.zed-i18n.packages.${pkgs.stdenv.hostPlatform.system}.zed-i18n;
}
```

追従は利用側で:

```console
$ nix flake update zed-i18n
```

## 手動でバージョンを進める

```console
$ nix run nixpkgs#nix-update -- --flake zed-i18n
```

## ライセンス

- **Zed 本体**: GPL-3.0（`meta.license` に反映）。
- **zed-i18n の翻訳**: VS Code および VS Code 言語パックの内容は
  Microsoft Corporation の著作物。翻訳はそれらを参照して作られている。
  詳細は [LI-NA/zed-i18n](https://github.com/LI-NA/zed-i18n) の README を参照。
- **このリポジトリ自身のコード**（`flake.nix`, `pkgs/*.nix`, CI）: MIT（`LICENSE`）。

本リポジトリは Zed / zed-i18n のバイナリを再配布しないため、
上記の第三者ライセンスに基づく配布義務は生じない（参照のみ）。
