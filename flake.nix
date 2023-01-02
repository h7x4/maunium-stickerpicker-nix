{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";

    maunium-stickerpicker = {
      url = "github:maunium/stickerpicker";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, maunium-stickerpicker }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    fetchers = pkgs.callPackage ./fetchers.nix { };
    createStickerPicker = pkgs.callPackage ./createStickerPicker.nix {
      inherit maunium-stickerpicker fetchers;
      inherit (self.packages.${system}) stickerpicker-tools;
    };
  in {
    inherit createStickerPicker;

    packages.${system} = {
      default = self.packages.${system}.stickerpicker-tools;
      stickerpicker-tools = pkgs.python3Packages.buildPythonPackage {
        name = "stickerpicker-tools";
        src = maunium-stickerpicker;

        propagatedBuildInputs = with pkgs.python3Packages; [
          aiohttp
          yarl
          pillow
          telethon
          cryptg
          python-magic
          pkgs.cacert
        ];
        doCheck = false;
      };
    };
  };
}
