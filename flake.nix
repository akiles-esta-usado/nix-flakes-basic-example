{
  description = "A very basic flake";

  inputs = {
    librelane.url = "github:librelane/librelane?ref=2.4.0";
    nixpkgs.follows = "librelane/nix-eda/nixpkgs";
  };

  outputs = { self, nixpkgs, ... }:
  let
    lib = nixpkgs.lib;
    eachSystem = lib.genAttrs [
      "x86_64-linux"
      # "aarch64-linux"
      # "x86_64-darwin"
      # "aarch64-darwin"
    ];
  in {

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

  };
}
