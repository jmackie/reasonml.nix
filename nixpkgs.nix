with builtins.fromJSON (builtins.readFile ./nixpkgs-src.json);
import (builtins.fetchTarball {
  name = "nixpkgs";
  inherit sha256;
  url = "${url}/archive/${rev}.tar.gz";
})
