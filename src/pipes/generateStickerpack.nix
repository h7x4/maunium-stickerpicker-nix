{ pkgs, lib }:

# This is the end pipe.
# It is the only pipe that is allowed to return something
# other than a list of stickers, a json string index that the
# stickerpicker can use to load the stickers.

{ id, title, stickers, domain, ... }:
{
  inherit title id;
  stickers = map (s: {
    inherit (s) id;
    body = s.title;
    url = "mxc://${domain}/${s.id}";
    msgtype = "m.sticker";
    info = s.mediainfo // {
      thumbnail_url = "mxc://${domain}/${s.id}";
      thumbnail_info = s.mediainfo;
    };
  }) stickers;
}
