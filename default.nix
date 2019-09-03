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
  merlin-lsp = merlin-lsp-for "4_07";
  merlin-lsp-for = version:
    pkgs.ocaml-ng."ocamlPackages_${version}".callPackage merlin-lsp-package { };
  merlin-lsp-package = ./merlin-lsp;

  # not a great idea
  esy = esy-env {
    name = "esy";
    runScript = "esy";
  };

  esy-env = pkgs.callPackage ./esy rec {
    fetchNpmRelease = pkgs.callPackage ./esy/fetchNpmRelease.nix { };
    esy-solve-cudf =
      pkgs.callPackage ./esy/esy-solve-cudf.nix { inherit fetchNpmRelease; };
  };
}
