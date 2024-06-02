[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

# maunium-stickerpicker-nix

A nix module for [maunium/stickerpicker][maunium-stickerpicker]

This module hosts one or more stickerpicker instances together with a mock homeserver that hosts the stickerpacks.
The mock server will respond to the relevant matrix endpoints that retrieves mxc urls for the stickers.
Unlike the upstream project, the stickers are never uploaded to the real homeserver, but are instead served from this mock server.
The build steps for the stickerpicker are ignored, and the sticker index is generated using nix and used as a replacement.

## Usage:

Here's an example instance of the stickerpicker, using the nixos module:

```nix
services.maunium-stickerpicker = {
  enable = true;
  instances."my-sticker-picker" = {
    realMatrixDomain = "matrix.myserver.com";

    # This creates a virtualhost in nginx, and will by default request Let's Encrypt certificates
    # Feel free to override the virtualHost configuration to your liking
    stickerMatrixDomain = "matrix-stickerpacks.myserver.com";

    stickerPacks = [
      {
        id = "stickerpack1";
        title = "Stickerpack 1";
        stickers = [
          {
            id = "sticker1";
            title = "Sticker 1";
            path = ./stickers/stickerpack1/sticker1.png;
          }
          {
            id = "sticker2";
            title = "Sticker 2";
            path = ./stickers/stickerpack1/sticker2.png;
          }
          {
            id = "moving-sticker";
            title = "Moving Sticker";
            path = ./stickers/stickerpack1/moving-sticker.gif;
          }
          {
            id = "single-remote-sticker";
            title = "Single Remote Sticker";
            url = "https://example.com/sticker.png";
            hash = "sha256-AAAAAA...";
          }
        ];
      }
      {
        id = "stickerpack2";
        title = "Stickerpack 2";
        stickers = let
          jsonFile = pkgs.writeText "stickerpack2.json" ''
            [
              { "url": "https://example.com/sticker1.png" },
              { "url": "https://example.com/sticker2.jpg" }
            ]
          '';
        in jsonFile;
        hash = "sha256-AAAAAA...";
        outputType = "png";
      }
    ];
  };
};
```

The stickerpicker should now be hosted on `https://matrix-stickerpacks.myserver.com/stickerpicker/`.
See [upstream docs](https://github.com/maunium/stickerpicker/wiki/Enabling-the-widget) for how to enable the widget in your client.

[maunium-stickerpicker]: https://github.com/maunium/stickerpicker
