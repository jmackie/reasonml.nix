{ pkgs ? import ./nixpkgs.nix { } }:

rec {
  bucklescript = pkgs.callPackage ./bucklescript { };
  bs-platform = bucklescript.bs-platform { };
  inherit (bucklescript) ocaml_BS;

  bsansouci = pkgs.callPackage ./bsansouci { inherit ocaml_BS; };
  bsb-native = bsansouci.bsb-native { };

  reason-language-server =
    pkgs.ocaml-ng.ocamlPackages_4_07.callPackage ./reason-language-server { };

  # Sadly this won't (currently) build with ocaml 4.2.x, so can't be used 
  # alongside the reason-language-server for *.ml code
  # https://github.com/ocaml/merlin/issues/937
  merlin-lsp = pkgs.ocaml-ng.ocamlPackages_4_07.callPackage ./merlin-lsp { };

  # Currently snagged on:
  # https://github.com/esy/esy/pull/962
  esy = pkgs.callPackages ./esy { };
}
