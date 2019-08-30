{ pkgs ? import ./nixpkgs.nix { } }:

rec {
  bucklescript = pkgs.callPackage ./bucklescript { };
  bsansouci = pkgs.callPackage ./bsansouci { inherit (bucklescript) ocaml_BS; };
  reason-language-server = pkgs.ocaml-ng.ocamlPackages_4_07.callPackage
    ./reason-language-server/release.nix { };

  # Sadly this won't (currently) build with ocaml 4.2.x, so can't be used 
  # alongside the reason-language-server for *.ml code
  merlin-lsp = pkgs.ocaml-ng.ocamlPackages_4_07.callPackage ./merlin-lsp { };
}
