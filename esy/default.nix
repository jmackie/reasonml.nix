{ stdenv, buildFHSUserEnv, fetchgit, fetchNpmRelease, makeWrapper
, esy-solve-cudf }:
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

  # https://github.com/esy/esy/pull/962
in buildFHSUserEnv {
  name = "esy";
  targetPkgs = (pkgs: [
    esyRelease

    pkgs.coreutils
    pkgs.binutils
    pkgs.curl
    pkgs.gcc
    pkgs.m4
    pkgs.gnumake
    pkgs.which
    pkgs.git
    # NOTE: there are probably more things that need to go here...
  ]);
  runScript = "esy";

  #profile = ''
  #  export ESY__LOG=debug
  #'';
}
