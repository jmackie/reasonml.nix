{ pkgs ? import <nixpkgs> { } }: {
  bucklescript = pkgs.callPackage ./bucklescript { };
}
