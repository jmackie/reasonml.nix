{ stdenv, fetchgit, writers, python2, nodejs, jq }:
let
  bucklescript-src =
    builtins.fromJSON (builtins.readFile ./bucklescript-src.json);
  ocaml-src = builtins.fromJSON (builtins.readFile ./ocaml-src.json);
in rec {
  # This is a mash up of:
  #  - https://github.com/BuckleScript/bucklescript/blob/master/scripts/buildocaml.js
  #  - https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/compilers/ocaml/generic.nix
  ocaml = stdenv.mkDerivation {
    name = "ocaml";
    version = "4.02.3+BS";
    src = with ocaml-src;
      fetchgit {
        inherit url rev sha256;
        fetchSubmodules = false;
      };

    prefixKey = "-prefix ";
    configureFlags = [
      # NOTE: these are used by buildocaml.js but I don't think we want them here?
      # "-no-ocamlbuild"
      # "-no-curses"
      # "-no-graph"
      # "-no-pthread"
      # "-no-debugger"
    ];
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
    version = "1.9.0.git"; # build it and `./result/bin/ninja --version`
    src = with bucklescript-src;
      fetchgit {
        inherit url rev sha256;
        fetchSubmodules = false;
      };

    buildInputs = [ python2 ];

    # See `provideNinja()` in scripts/install.js
    buildPhase = ''
      pushd vendor/ninja
      tar xzvf ../ninja.tar.gz
      python ./configure.py --bootstrap
      popd
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp vendor/ninja/ninja $out/bin/ninja
    '';
  };

  bs-platform = stdenv.mkDerivation {
    name = "bs-platform";
    version = "5.1.1";
    src = with bucklescript-src;
      fetchgit {
        inherit url rev sha256;
        fetchSubmodules = false;
      };

    buildInputs = [ ocaml nodejs jq ];

    # NOTE: adapted from scripts/install.js
    buildPhase = ''
      ln -vs ${ninja}/bin/ninja ./lib/ninja.exe

      # Build the bucklescript compiler
      # (See `provideCompiler()` in scripts/install.js)
      pushd lib
      node -e 'console.log(require("../scripts/ninjaFactory.js").libNinja({ ocamlopt: "ocamlopt.opt", ext: ".exe", INCL: /* ocamlVersion */ "4.02.3", isWin: false }))' | tee release.ninja
      ./ninja.exe -f release.ninja
      rm release.ninja
      popd

      # Build libraries
      # (See `buildLibs()` in scripts/install.js)
      pushd jscomp
      tee release.ninja <<'RELEASE'
      stdlib = stdlib-402
      subninja runtime/release.ninja
      subninja others/release.ninja
      subninja $stdlib/release.ninja
      build all: phony runtime others $stdlib
      RELEASE
      ../lib/ninja.exe -f release.ninja --verbose
      rm release.ninja
      popd
    '';

    installPhase = ''
      mkdir -p $out
      cp package.json $out
      cp -r lib $out

      # Copy across built libs
      # (See `install()` in scripts/install.js)
      mkdir -p $out/lib/ocaml
      find jscomp/runtime -type f \
        \( -name 'js.*' -or -name '*.*cm*' \) \
        -exec cp {} $out/lib/ocaml \;

      find jscomp/others -type f \
        \( -name '*.ml' -or -name '*.mli' -or -name '*.*cm*' \) \
        -exec cp {} $out/lib/ocaml \;

      find jscomp/stdlib-402 -type f \
        \( -name '*.ml' -or -name '*.mli' -or -name '*.*cm*' \) \
        -exec cp {} $out/lib/ocaml \;

      # Link binaries
      # (See the `bin` field of package.json)
      mkdir -p $out/bin
      for bin in $(cat package.json | jq -r '.bin[]'); do
        ln -vs $out/$bin $out/bin/$(basename $bin)
      done
    '';

    # Test: init a new project and build it
    doInstallCheck = true;
    installCheckPhase = ''
      $out/bin/bsb -init install-check
      cd install-check
      ./node_modules/.bin/bsb -make-world
    '';
  };
}
