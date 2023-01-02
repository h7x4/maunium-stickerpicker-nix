[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

# maunium-stickerpicker-nix

Nix wrapper for [maunium/stickerpicker][maunium-stickerpicker]

## Usage:

Here's an example of a stickerpicker

```nix
myStickerPicker = createStickerPicker {
  homeserver = "https://my.matrix.server";
  userId = "@stickerbot:my.matrix.server";
  # You should probably encrypt this with either agenix, sops-nix or whatever else
  accessTokenFile = ./stickerbot_access_token.txt;
  sha256 = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  packs = [
    {
      type = "chatsticker";
      name = "pompom-tao3";
    }
    {
      type = "directory";
      src = ./myHomemadeStickers;
    }
  ];
};
```

Afterwards, you can easily host it in an nginx config

```nix
{ ... }:
{
services.nginx.enable = true;
services.nginx.virtualHosts."stickers.myhost.org" = {
    root = myStickerPicker;
  };
}
```

## List of available fetchers

| Site | Type Name |Required Arguments |
|------|-----------|-------------------|
| `<local dir>` | `directory` | `src` (path to a local dir with image files) |
| https://chatsticker.com | `chatsticker` | `name` (see url) |

## Some notes

To use this, leave the `sha256` empty at first, build the stickerspicker with whatever stickers you'd like, and paste the `sha256` from the error message back into your code.

Normally, [maunium/stickerpicker][maunium-stickerpicker] would cache the stickers in a config file, and reuse the config file on the next run in order not to.
This does not work with Nix' determinism.
Thus every time you want to add just 1 more stickerpack (or any other kind of edit), this will reupload all stickers.
In order to make it easier to delete all sticker once in a while, I would recommend creating a separate user (I've called mine `stickerbot`), whose only purpose is to be the owner of a bunch of sticker media files.
Whenever you want to clean up the media store, just delete all the media file of `stickerbot` (**THIS WILL BREAK OLDER MESSAGES**)

[maunium-stickerpicker]: https://github.com/maunium/stickerpicker
