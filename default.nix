{ pkgs ? import <nixpkgs> { } }: {
  inherit (pkgs.callPackage ./bucklescript { }) bs-platform ocaml ninja;
}
