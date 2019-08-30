{ pkgs ? import ./nixpkgs.nix { } }:

rec {
  bucklescript = pkgs.callPackage ./bucklescript { };
  bsansouci = pkgs.callPackage ./bsansouci { inherit (bucklescript) ocaml_BS; };
}
