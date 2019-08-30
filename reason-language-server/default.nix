{ fetchFromGitHub, buildDunePackage, ppx_tools_versioned
, ocaml-migrate-parsetree, reason }:
buildDunePackage rec {
  pname = "reason-language-server";
  version = "1.7.1";
  src = fetchFromGitHub {
    owner = "jaredly";
    repo = pname;
    rev = version;
    sha256 = "1yprrwf0zfvil0xhwnifr1cw2acyxqrf03dz62y67y2i1zrgk68i";
  };
  buildInputs = [ ppx_tools_versioned ocaml-migrate-parsetree reason ];
  postInstall = ''
    ln -vs $out/bin/Bin $out/bin/reason-language-server
  '';
}
