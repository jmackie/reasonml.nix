{ pkgs ? import <nixpkgs> { } }: {
  bucklescript = pkgs.callPackage ./bucklescript { };
  bsansouci = pkgs.callPackage ./bsansouci { };
}
