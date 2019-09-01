{ stdenv, lib, fetchNpmRelease }:
stdenv.mkDerivation rec {
  name = "esy-solve-cudf";
  version = "0.1.10";
  src = fetchNpmRelease {
    inherit name version;
    sha256 = "09azdwk9hmdg9la52msr6kn32gp86zpz5dh26f9n66rlrscbjpd6";
  };

  buildInputs = [ stdenv.cc.cc.lib ]; # libstdc++.so.6

  buildCommand = ''
    cp -r --no-preserve=mode,ownership,timestamps $src $out
    exe=$out/esySolveCudfCommand.exe
    ${if stdenv.isDarwin then ''
      mv $out/platform-darwin/esySolveCudfCommand.exe $exe
      chmod 555 $exe
    '' else ''
      mv $out/platform-linux/esySolveCudfCommand.exe $exe
      chmod u+w $exe
      patchelf --interpreter ${stdenv.cc.bintools.dynamicLinker} --set-rpath ${
        lib.makeLibraryPath buildInputs
      } $exe
      chmod u-w $exe
      chmod 555 $exe
    ''}
  '';
}
