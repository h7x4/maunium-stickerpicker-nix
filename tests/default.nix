{
  pkgs,
  lib,
  system ? pkgs.system,

  nixpkgs,
  autoFetcher,
  generateStickerpack,
  generateStickerpicker,
  nixosModule,
  ...
}:
let
  stickerpack-data = {
    id = "my-stickerpack";
    title = "Test Stickerpack";
    stickers = [
      {
        id = "sticker-1";
        title = "Test Sticker 1";
        path = ./test-data/test.png;
      }
      {
        id = "sticker-2";
        title = "Test Sticker 2";
        path = ./test-data/test.png;
        outputType = "jpg";
      }
    ];
  };
in {
  autoStickerpack =
    let
      attrs = autoFetcher {
        id = "auto-fetcher-stickerpack";
        stickers = builtins.fromJSON (builtins.readFile ./test-data/test.json);
        hash = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
      };
    in
      pkgs.writeText "auto-fetcher-stickerpack-attrs.json" (builtins.toJSON attrs);
  stickerpack = generateStickerpack stickerpack-data;
  stickerpicker = generateStickerpicker {
    instanceName = "my-stickerpicker";
    realMatrixDomain = "matrix.matrix.org";
    stickerMatrixDomain = "stickers.matrix.matrix.org";
    stickerPacks = [ stickerpack-data ];
  };

  # build using `nix build .#tests.nixos.config.system.build.toplevel`
  nixos = nixpkgs.lib.nixosSystem {
    system = system;
    modules = [
      nixosModule
      {
        boot.isContainer = true;

        security.acme = {
          acceptTerms = true;
          defaults.email = "test@email.com";
        };

        # Puts nginx config in /etc/nginx/nginx.conf
        services.nginx.enableReload = true;
        services.maunium-stickerpicker = {
          enable = true;
          instances."my-stickerpicker" = {
            realMatrixDomain = "matrix.website.com";
            stickerMatrixDomain = "stickers.matrix.website.com";
            stickerPacks = [
              stickerpack-data
              {
                id = "my-stickerpack-2";
                title = "Test stickerpack 2";
                stickers = ./test-data/test.json;
                hash = "sha256-g7qPoafR2dwDrhMp2gTjszadvoCrbscTgw2DgEY8T0A";
              }
            ];
          };
        };
      }
    ];
  };
}
