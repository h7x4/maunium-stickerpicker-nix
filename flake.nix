{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";

    mauniumStickerpicker = {
      url = "github:maunium/stickerpicker";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, mauniumStickerpicker }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    pipes = {
      assignIds = pkgs.callPackage ./src/pipes/assignIds.nix { };
      assignTitles = pkgs.callPackage ./src/pipes/assignTitles.nix { };
      autoFetcher = pkgs.callPackage ./src/pipes/autoFetcher.nix { };
      imagemagickConverter = pkgs.callPackage ./src/pipes/imagemagickConverter.nix { };
      mediainfoExtractor = pkgs.callPackage ./src/pipes/mediainfoExtractor.nix { };
      generateStickerpack = pkgs.callPackage ./src/pipes/generateStickerpack.nix { };
      prefixIdsWithPackId = pkgs.callPackage ./src/pipes/prefixIdsWithPackId.nix { };
    };

    generateStickerpicker = pkgs.callPackage ./src/generateStickerpicker.nix {
      inherit (self) pipes;
      inherit mauniumStickerpicker;
    };

    packages.${system} = {
      default = self.packages.${system}.stickerpicker-tools;
      stickerpicker-tools = pkgs.callPackage ./src/pkgs/stickerpicker-tools.nix {
        inherit mauniumStickerpicker;
      };
    };


    docs = let 
      inherit (pkgs) lib;

      scrubbedPkgsModule = {
        imports = [{
          _module.args = {
            # pkgs = lib.mkForce (nmd.scrubDerivations "pkgs" pkgs);
            pkgs = pkgs;
            pkgs_i686 = lib.mkForce { };
          };
        }];
      };

      dontCheckDefinitions = { _module.check = false; };
      
      options = builtins.removeAttrs ((lib.evalModules {
        modules = [
          scrubbedPkgsModule
          dontCheckDefinitions
          self.nixosModules.default
        ];
      }).options) ["_module"];

    in
      assert lib.traceSeqN 100 options true;
      pkgs.nixosOptionsDoc {
        inherit options;
      };

    nixosModules.default = import ./src/module.nix { inherit (self) generateStickerpicker; };

    tests = import ./tests {
      inherit nixpkgs pkgs;
      inherit (pkgs) lib;
      inherit (self) generateStickerpicker;
      inherit (self.pipes) assignIds assignTitles autoFetcher imagemagickConverter mediainfoExtractor generateStickerpack;
      nixosModule = self.nixosModules.default;
    };
  };
}
