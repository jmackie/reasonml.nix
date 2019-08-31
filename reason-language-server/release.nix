{ stdenv, fetchurl, unzip }:
stdenv.mkDerivation rec {
  name = "reason-language-server";
  version = "1.7.1";
  src = fetchurl {
    url =
      "https://github.com/jaredly/reason-language-server/releases/download/${version}/rls-linux.zip";
    sha256 = "18bvadkql0r71q4a6ywcqz184sig770pps32vz9r99y5anj1cxhb";
  };
  buildInputs = [ unzip ];
  buildCommand = ''
    unzip $src
    mkdir -p $out/bin
    EXE=$out/bin/${name}
    install -D -m555 rls-linux/${name} $EXE
    ${if stdenv.isDarwin then
      ""
    else ''
      chmod u+w $EXE
      patchelf --interpreter ${stdenv.cc.bintools.dynamicLinker} $EXE
      chmod u-w $EXE
    ''}'';
}
