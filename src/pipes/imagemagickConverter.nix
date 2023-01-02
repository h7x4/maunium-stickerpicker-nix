{ pkgs, lib, ... }:
let
  inherit (pkgs.callPackage ../utils.nix { }) withDefaultAttr;
in
{
  stickers,
  id,
  outputType ? null,
  extraConversionArgs ? [ ],
  ...
}:
let
  newStickers = lib.pipe stickers [
    (map (withDefaultAttr "outputType" outputType))
    (map (withDefaultAttr "dontConvert" false))
    (map (sticker: sticker // { outputType = lib.mapNullable lib.toUpper sticker.outputType; }))
    (map (withDefaultAttr "extraConversionArgs" extraConversionArgs))
  ];

  commands = lib.pipe newStickers [
    (builtins.filter (s: s.outputType != null && !s.dontConvert))
    (map (s: let
      in_ = s.path;
      args = lib.concatStringsSep " " s.extraConversionArgs;
      out = "${s.outputType}:$out/${s.id}";
    in "${pkgs.imagemagick}/bin/convert ${in_} ${args} ${out}"))
  ];

  convertedStickersDrv = pkgs.runCommandLocal "maunium-stickerpicker-${id}-converted" { } ''
    mkdir -p $out
    ${builtins.concatStringsSep "\n" commands}
  '';
in
    map (sticker: sticker // {
      path = if sticker.outputType != null
               then "${convertedStickersDrv}/${sticker.id}"
               else sticker.path;
    }) newStickers
