{ stdenv, curl, cacert, jq }:
{ name, pkg ? name, version, sha256 }:
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
}
