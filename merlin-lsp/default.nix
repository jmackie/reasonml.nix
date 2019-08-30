{ fetchgit, buildDunePackage, yojson, ppx_deriving_yojson }:
let
  merlin-src = {
    name = "ocaml-merlin";
  } // builtins.fromJSON (builtins.readFile ./merlin-src.json);
in buildDunePackage rec {
  pname = "merlin-lsp";
  version = "3.3.1";
  src = with merlin-src;
    fetchgit {
      inherit name url rev sha256;
      fetchSubmodules = false;
    };
  buildInputs = [ yojson ppx_deriving_yojson ];
}
