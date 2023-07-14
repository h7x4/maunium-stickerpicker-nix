{ pkgs, lib, ... }:
let
  inherit (pkgs.callPackage ../utils.nix { }) withDefaultAttr;
in
stickerpack@{
  stickers,
  ...
}:
# NOTE: this will be prefixed with the pack id at a later stage.
lib.imap1 (i: withDefaultAttr "id" "sticker-${toString i}") stickers
