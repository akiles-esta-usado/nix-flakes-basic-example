{
  description = "A very basic flake";

  inputs = {
    librelane.url = "github:librelane/librelane?ref=2.4.0";
    nixpkgs.follows = "librelane/nix-eda/nixpkgs";
  };

  outputs = { 
    self,
    nixpkgs,
    ... }:
  let
    lib = nixpkgs.lib;
    eachSystem = lib.genAttrs [
      "x86_64-linux"
      # "aarch64-linux"
      # "x86_64-darwin"
      # "aarch64-darwin"
    ];
  in {
    packages = eachSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        hello = pkgs.hello;
        default = self.packages.${system}.hello;
      }
    );

    # packages.x86_64-linux.hello = pkgs.hello;
    # packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

  };
}

/**
  legacyPackages
  - Es un nombre sustituto al de "packages"
  - `nix flake show` sería horriblemente lento si se reutilizara el mismo nombre
  - Por defecto, no muestra paquetes listados en "legacyPackages".
 */