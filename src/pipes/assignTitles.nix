{ pkgs, lib, ... }:
let
  inherit (pkgs.callPackage ../utils.nix { }) withDefaultAttr;
in
{
  stickers,
  titlePrefix,
  generateTitle ? (titlePrefix: n: "${titlePrefix} - Sticker ${toString n}"),
  ...
}:
  lib.imap1 (i: withDefaultAttr "title" (generateTitle titlePrefix i)) stickers