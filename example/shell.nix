{ pkgs ? import ./../nixpkgs.nix { } }:
let
  reasonml = import ./.. { inherit pkgs; };
  bs-platform = reasonml.bucklescript.bs-platform { };

  ln-bs-platform = pkgs.writers.writeBashBin "ln-bs-platform" ''
    if [ -d node_modules ]; then 
      if [ -e node_modules/bs-platform ]; then
        rm -rf node_modules/bs-platform
      fi
    else
      mkdir -v node_modules
    fi
    ln -vsf ${bs-platform} ./node_modules/bs-platform

    [ -d node_modules/.bin ] || mkdir -v node_modules/.bin
    for bin in $(ls ${bs-platform}/bin); do
      ln -vsf "${bs-platform}/bin/$bin" "node_modules/.bin/$bin"
    done
  '';
in pkgs.mkShell {
  buildInputs = [
    ln-bs-platform
    pkgs.nodejs-10_x
    pkgs.reason
    pkgs.ocamlformat
    reasonml.reason-language-server
    reasonml.merlin-lsp
    #reasonml.bucklescript.ocaml_BS
    #pkgs.ocaml-ng.ocamlPackages_4_02.ocaml
    #pkgs.nodePackages_10_x.ocaml-language-server
    #merlin_2-5-4
  ];
}
