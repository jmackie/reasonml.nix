{ pkgs ? import ./nixpkgs.nix { } }:

rec {
  bucklescript = pkgs.callPackage ./bucklescript { };
  bsansouci = pkgs.callPackage ./bsansouci { inherit (bucklescript) ocaml_BS; };
  reason-language-server = pkgs.ocaml-ng.ocamlPackages_4_07.callPackage
    ./reason-language-server/release.nix { };
}
