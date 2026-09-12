{
  description = "Wave Management Simulator - An interactive educational tool for learning League of Legends wave management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    effekt-nix = {
      url = "github:jiribenes/effekt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, effekt-nix }:
    let
      ## Builds for all systems supported by effekt-nix.
      ## If you want only some specific systems, do the following instead:
      # systems = ["aarch64-linux" "aarch64-darwin"];
      systems = effekt-nix.lib.supportedSystems;

      forAllSystems = nixpkgs.lib.genAttrs systems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

      ## Project configuration
      pname = "wave-management-sim";         # package name
      version = "0.1.0";                 # package version
      mainFile = "src/main.effekt";      # relative path to entrypoint (as a string)
      testFiles = [ "src/test.effekt" ]; # relative paths to tests (as a string)

      ## Effekt configuration
      effektConfig = {
        ## Use latest available version from effekt-nix
        ## (Will be auto-updated by CI weekly)
        # version = null;  # null = latest available

        ## Select the backends that your project works on:
        backends = bs: with bs; [ js ];
      };
    in {
      packages = forAllSystems (system:
        let
          effekt-lib = effekt-nix.lib.mkLib nixpkgsFor.${system};

          # Chooses the correct Effekt package.
          effektBuild = effekt-lib.getEffekt effektConfig;
        in {
          default = effekt-lib.buildEffektPackage {
            inherit pname version;
            src = ./.;
            main = mainFile;
            tests = testFiles;

            effekt = effektBuild;
            inherit (effektConfig) backends;
          };
        }
      );

      devShells = forAllSystems (system:
        let
          effekt-lib = effekt-nix.lib.mkLib nixpkgsFor.${system};

          # Chooses the correct Effekt package.
          effektBuild = effekt-lib.getEffekt effektConfig;
        in {
          default = effekt-lib.mkDevShell {
            effekt = effektBuild;
            inherit (effektConfig) backends;
          };
        }
      );
    };
}
