{ stdenv, fetchgit, writers, python2, nodejs, jq, ocaml_BS }:
let
  bucklescript-src = {
    name = "bsansouci-bucklescript";
  } // builtins.fromJSON (builtins.readFile ./bucklescript-src.json);

in rec {
  ninja = stdenv.mkDerivation {
    name = "ninja";
    version = "1.8.2"; # build it and `./result/bin/ninja --version`
    src = with bucklescript-src;
      fetchgit {
        inherit name url rev sha256;
        fetchSubmodules = false;
      };
    sourceRoot = "${bucklescript-src.name}/vendor/ninja";

    buildInputs = [ python2 ];

    # See `provideNinja()` in scripts/install.js
    buildPhase = "python ./configure.py --bootstrap";
    installPhase = ''
      mkdir -p $out/bin
      cp ninja $out/bin/ninja
    '';
  };

  # NOTE: This doesn't work if `ocaml` is built from the bundled checkout.
  bsb-native = { ocaml ? ocaml_BS }:
    stdenv.mkDerivation {
      name = "bsb-native";
      version = "4.0.1100";
      src = with bucklescript-src;
        fetchgit {
          inherit name url rev sha256;
          fetchSubmodules = false;
        };

      buildInputs = [ nodejs ocaml ninja jq ];

      buildPhase = ''
        ln -vs ${ninja}/bin/ninja lib/ninja.exe
        ln -vs ${ocaml}/* vendor/ocaml/

        make world-native

        pushd jscomp/runtime
        ninja -t clean && ninja 
        popd 

        pushd jscomp/others
        ninja -t clean && ninja 
        popd

        pushd jscomp/stdlib-402
        ninja -t clean && ninja 
        popd

        make install
      '';

      installPhase = ''
        mkdir -p $out
        cp package.json $out
        cp -r lib $out

        # Link binaries
        # (See the `bin` field of package.json)
        mkdir -p $out/bin
        for bin in $(cat package.json | jq -r '.bin[]'); do
          ln -vs $out/$bin $out/bin/$(basename $bin)
        done
      '';
    };
}
