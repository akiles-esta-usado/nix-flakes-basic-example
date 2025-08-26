{
  description = "A very basic flake";

  # Based on
  # - https://librelane.readthedocs.io/en/latest/getting_started/common/nix_installation/installation_win.html
  # nixConfig = {
  #   extra-substituters = [
  #     "https://nix-cache.fossi-foundation.org"
  #   ];
  #   extra-trusted-public-keys = [
  #     "nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs="
  #   ];
  # };

  inputs = {
    librelane.url = "github:librelane/librelane?ref=2.4.0";
    nixpkgs.follows = "librelane/nix-eda/nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    librelane,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;
    eachSystem = lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    overlays = {
      default = lib.composeManyExtensions [
        (
          final: prev: let
            callPackage = lib.callPackageWith final;
          in {
            openvaf = callPackage ./openvaf.nix {};
          }
        )
      ];
    };

    legacyPackages = eachSystem (
      system:
        import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        }
    );

    packages = eachSystem (
      system: let
        pkgs = self.legacyPackages.${system};
        self_pkgs = self.packages.${system};
      in {
        hello = pkgs.hello;
        default = self_pkgs.hello;
      }
    );

    # packages = eachSystem (
    #   system: let
    #     pkgs = self.legacyPackages.${system};
    #   in
    #     {
    #       inherit (pkgs) magic magic-vlsi netgen klayout klayout-gdsfactory tclFull tk-x11 iverilog verilator xschem ngspice bitwuzla yosys yosys-sby yosys-eqy yosys-lighter yosys-slang;
    #       inherit (pkgs.python3.pkgs) gdsfactory gdstk tclint;
    #     }
    #     // lib.optionalAttrs self.legacyPackages."${system}".stdenv.hostPlatform.isLinux {
    #       inherit (pkgs) xyce;
    #       inherit (pkgs.python3.pkgs) cocotb;
    #     }
    #     // lib.optionalAttrs self.legacyPackages."${system}".stdenv.hostPlatform.isx86_64 {
    #       inherit (pkgs) yosys-ghdl;
    #     }
    # );

    devShells = eachSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        librelane_pkgs = librelane.legacyPackages.${system};
      in {
        default = pkgs.mkShellNoCC {
          packages = [
            pkgs.hello
            librelane_pkgs.ciel # Download pdks
            librelane_pkgs.xschem # schematics
            librelane_pkgs.ngspice # simulations
            librelane_pkgs.magic # layout
            librelane_pkgs.klayout # layout
            librelane_pkgs.netgen # LVS
            librelane_pkgs.klayout-gdsfactory
            # librelane_pkgs.gaw
            # librelane_pkgs.cvc # Circuit validity
            librelane_pkgs.python3.pkgs.psutil
            # librelane_pkgs.python3.pkgs.cace # Simulation framework

            librelane_pkgs.yosysFull # RTL Synthesis
            librelane_pkgs.openroad # Place and Route
            librelane_pkgs.openroad-abc # Seq logic synthesis & Formal Verification
            librelane_pkgs.verilator # Simulation
            librelane_pkgs.opensta
            librelane_pkgs.python3.pkgs.librelane # Digital flow
            librelane_pkgs.python3.pkgs.gdsfactory # Geometric
            librelane_pkgs.python3.pkgs.cocotb # Simulation framework
          ];

          shellHook = ''
            export NIX=1
            export PDK=ihp-sg13g2
            export STD_CELL_LIBRARY=sg13g2_stdcell

            export PDKPATH=$PDK_ROOT/$PDK
            export SPICE_USERINIT_DIR=$PDK_ROOT/$PDK/libs.tech/ngspice
            export KLAYOUT_HOME=$PDK_ROOT/$PDK/libs.tech/klayout
            export KLAYOUT_PATH=$KLAYOUT_HOME

            export PDK_COMMIT=8fd69a7
            ciel enable --pdk-family $PDK $PDK_COMMIT

            alias xschem='xschem --rcfile $PDK_ROOT/$PDK/libs.tech/xschem/xschemrc'
            alias xschemtcl='xschem --rcfile $PDK_ROOT/$PDK/libs.tech/xschem/xschemrc'
            alias magic='magic -rcfile $PDK_ROOT/$PDK/libs.tech/magic/*.magicrc'

            IHP_OPENVAF_DIR=$PDK_ROOT/ihp-sg13g2/libs.tech/ngspice/openvaf
            if [ ! -f "$IHP_OPENVAF_DIR/psp103_nqs.osdi" ]; then
                echo "Compiling ihp-sg13g2 osdi files"
                openvaf $IHP_OPENVAF_DIR/psp103_nqs.va --output /tmp/psp103_nqs.osdi

                if [ $? -eq 0 ]; then
                    echo "Compilation succeded"
                    sudo mv /tmp/psp103_nqs.osdi $IHP_OPENVAF_DIR
                else
                    echo "Compilation failed, reopen another terminal"
                fi
            fi

            echo -e "\e[35mWelcome to the Development Environment\e[0m"
          '';
        };
      }
    );
  };
}
/*
legacyPackages
- Es un nombre sustituto al de "packages"
- `nix flake show` sería horriblemente lento si se reutilizara el mismo nombre
- Por defecto, no muestra paquetes listados en "legacyPackages".
*/
/*
El formato usado por "alejandra" tiene los siguientes criterios:

- lambda functions empiezan en nueva línea y con un nivel de identación adicional
- la declaración de función es como sigue

system: let
  initial = assignments;
in {
  atrrSet = values
}
*/

