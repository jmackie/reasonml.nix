{ stdenv, lib, curl, cacert, nodejs, jq, makeWrapper }:
let
  fetchNpmRelease = { name, pkg ? name, version, sha256 }:
    stdenv.mkDerivation {
      name = "${name}-release-${version}";
      buildInputs = [ curl cacert jq ];
      buildCommand = ''
        TARBALL=$(curl https://registry.npmjs.org/${pkg}/ | jq -r '.versions["${version}"].dist.tarball')
        mkdir -p $out
        curl $TARBALL | tar xvz -C $out --strip-components 1
      '';
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
      outputHash = sha256;
    };
  esy-solve-cudf = stdenv.mkDerivation rec {
    name = "esy-solve-cudf";
    version = "0.1.10";
    src = fetchNpmRelease {
      inherit name version;
      sha256 = "09azdwk9hmdg9la52msr6kn32gp86zpz5dh26f9n66rlrscbjpd6";
    };

    buildInputs = [ stdenv.cc.cc.lib ]; # libstdc++.so.6
    libPath = lib.makeLibraryPath buildInputs;

    buildCommand = ''
      cp -r --no-preserve=mode,ownership,timestamps $src $out
      exe=$out/esySolveCudfCommand.exe
      mv $out/platform-linux/esySolveCudfCommand.exe $exe
      chmod u+w $exe
      patchelf --interpreter ${stdenv.cc.bintools.dynamicLinker} --set-rpath ${libPath} $exe
      chmod u-w $exe
      chmod 555 $exe
    '';
  };
in stdenv.mkDerivation rec {
  name = "esy";
  version = "0.6.0-175b3f";
  src = fetchNpmRelease {
    inherit name version;
    pkg = "@esy-nightly/esy";
    sha256 = "183xdna2qn3rp3zihhwkp515m5awld6kq03dmv9xd3f4p8jmibkv";
  };
  meta.priority = "1"; # because bs-platform also installs a root package.json
  buildInputs = [ nodejs makeWrapper ];
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
}
