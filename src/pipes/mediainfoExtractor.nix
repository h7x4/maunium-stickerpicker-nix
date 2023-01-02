{ pkgs, lib, ... }:
{ stickers, id, ... }: let
  format = ''"\(.[1].Width) \(.[1].Height) \(.[0].FileSize) \(.[0].InternetMediaType)"'';

  mediainfoFiles = pkgs.runCommandLocal
    "maunium-stickerpack-${id}-mediainfo"
    { buildInputs = with pkgs; [ mediainfo jq ]; }
    (lib.pipe stickers [
      (map (s: "mediainfo -f --Output=JSON ${s.path} | jq '.media.track | ${format}' > $out/${s.id}.json"))
      (builtins.concatStringsSep "\n")
      (x: "mkdir -p $out\n" + x)
    ]);

  nullWarning = attr: sticker: ''
    mediainfo: ${attr} is null for image ${sticker.id}

    This usually means that the format of the sticker is unrecognized by mediainfo.
    Try converting the format using the `outputType` option.

    More info:
    ${builtins.toJSON sticker}
  '';

  appendMediainfo = sticker@{ title, id, path, ... }: let
    mediainfo = lib.pipe "${mediainfoFiles}/${id}.json" [
      lib.fileContents
      (lib.removePrefix "\"")
      (lib.removeSuffix "\"")
      (lib.splitString " ")
      (lib.zipListsWith lib.nameValuePair [
        "w" "h" "size" "mimetype"
      ])
      builtins.listToAttrs
      (attrs@{ w, h, size, mimetype, ... }:
        assert
          (lib.assertMsg (w != "null") (nullWarning "width" sticker))
          && (lib.assertMsg (h != "null") (nullWarning "height" sticker))
          && (lib.assertMsg (size != "null") (nullWarning "size" sticker))
          && (lib.assertMsg (mimetype != "null") (nullWarning "mimetype" sticker));
        attrs)
      (attrs@{ w, h, size, ... }: attrs // {
        w = lib.toInt w;
        h = lib.toInt h;
        size = lib.toInt size;
      })
    ];
  in
    sticker // { inherit mediainfo; };
in
  map appendMediainfo stickers
