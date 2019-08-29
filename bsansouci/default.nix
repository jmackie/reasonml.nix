{ stdenv, fetchgit, writers, python2, nodejs, jq }:
let
  bucklescript-src = {
    name = "bsansouci-bucklescript";
  } // builtins.fromJSON (builtins.readFile ./bucklescript-src.json);

in rec {
  # This is a mash up of:
  #  - https://github.com/BuckleScript/bucklescript/blob/master/scripts/buildocaml.js
  #  - https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/compilers/ocaml/generic.nix
  ocaml_BS = stdenv.mkDerivation {
    name = "ocaml_BS";
    version = "4.02.3+BS";
    src = with bucklescript-src;
      fetchgit {
        inherit name url rev sha256;
        fetchSubmodules = false;
      };
    sourceRoot = "${bucklescript-src.name}/vendor/ocaml";

    prefixKey = "-prefix ";
    configureFlags = [ ];
    buildInputs = [ ];
    buildFlags = "world bootstrap world.opt";
    postBuild = ''
      mkdir -p $out/include
      ln -sv $out/lib/ocaml/caml $out/include/caml
    '';
    installTargets = "install installopt";
    # TODO: could `fetchpatch` here instead...?
    patches = [ ./ocamlbuild.patch ];
  };

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

  bs-native = { ocaml ? ocaml_BS }:
    stdenv.mkDerivation {
      name = "bs-native";
      version = "4.0.1100";
      src = with bucklescript-src;
        fetchgit {
          inherit url rev sha256;
          fetchSubmodules = false;
        };

      buildInputs = [ ocaml nodejs jq ];

      # NOTE: adapted from scripts/install.js
      buildPhase = ''
        ln -vs ${ninja}/bin/ninja ./lib/ninja.exe
        # ...
      '';

      installPhase = ":";
    };
}
