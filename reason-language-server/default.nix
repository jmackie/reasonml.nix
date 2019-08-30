{ fetchgit, buildDunePackage, ppx_tools_versioned, ocaml-migrate-parsetree
, reason }:
let
  reason-language-server-src = {
    name = "jaredly-reason-language-server";
  } // builtins.fromJSON (builtins.readFile ./reason-language-server-src.json);

in buildDunePackage rec {
  pname = "reason-language-server";
  version = "1.7.1";
  src = with reason-language-server-src;
    fetchgit {
      inherit name url rev sha256;
      fetchSubmodules = false;
    };
  buildInputs = [ ppx_tools_versioned ocaml-migrate-parsetree reason ];
  postInstall = ''
    ln -vs $out/bin/Bin $out/bin/reason-language-server
  '';
}
