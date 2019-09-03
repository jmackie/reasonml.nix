{ stdenv, lib, buildFHSUserEnv, fetchgit, fetchNpmRelease, makeWrapper
, esy-solve-cudf, cacert }:
overrideFHSUserEnv:
let
  esyRelease = stdenv.mkDerivation rec {
    name = "esy-npm";
    version = "0.6.0-175b3f";
    src = fetchNpmRelease {
      inherit name version;
      pkg = "@esy-nightly/esy";
      sha256 = "183xdna2qn3rp3zihhwkp515m5awld6kq03dmv9xd3f4p8jmibkv";
    };
    meta.priority = "1"; # because bs-platform also installs a root package.json
    buildInputs = [ makeWrapper ];
    buildCommand = ''
      cp -r --no-preserve=mode,ownership,timestamps $src $out
      rm -rf $out/_build
      ${if stdenv.isDarwin then ''
        find $out/platform-darwin -name '*.exe' -print0 | while IFS= read -r -d "" exe; do 
          chmod 555 $exe
        done
        rm -rf $out/_build
        cp -r $out/platform-darwin/_build $out/_build
      '' else ''
        find $out/platform-linux -name '*.exe' -print0 | while IFS= read -r -d "" exe; do 
          chmod u+w $exe
          patchelf --interpreter ${stdenv.cc.bintools.dynamicLinker} $exe
          chmod u-w $exe
          chmod 555 $exe
        done
        cp -r $out/platform-linux/_build $out/_build
      ''}

      mkdir -p $out/bin
      makeWrapper $out/_build/default/bin/esy.exe $out/bin/esy \
        --set ESY__SOLVE_CUDF_COMMAND ${esy-solve-cudf}/esySolveCudfCommand.exe
    '';
  };

  bootstrap = buildFHSUserEnv ((attrs: attrs // overrideFHSUserEnv attrs) ({
    name = "esy-bootstrap";
    targetPkgs = pkgs: [
      esyRelease

      pkgs.coreutils
      pkgs.binutils
      pkgs.curl
      pkgs.cacert # for https
      pkgs.perl # for shasum
      pkgs.patch
      pkgs.gcc # pkgs.clang?
      pkgs.m4
      pkgs.gnumake
      pkgs.which
      pkgs.git
      # NOTE: there are probably more things that need to go here...

    ];
    multiPkgs = pkgs: [ ];
    runScript = "esy";

    #profile = ''
    #  export ESY__LOG=debug
    #'';
  }));

  esySrc = builtins.fromJSON (builtins.readFile ./esy-src.json);

in stdenv.mkDerivation rec {
  name = "esy-${esySrc.rev}";
  src = fetchgit {
    inherit (esySrc) url rev sha256;
    fetchSubmodules = false;
  };
  # TODO: patch src
  # https://github.com/esy/esy/pull/962
  buildInputs = [ cacert ];
  buildPhase = ''
    export ESY__LOG=debug
    export ESY__PREFIX=$(pwd)
    ${bootstrap}/bin/esy-bootstrap install
    ${bootstrap}/bin/esy-bootstrap build
  '';

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = esySrc.sha256;
}
