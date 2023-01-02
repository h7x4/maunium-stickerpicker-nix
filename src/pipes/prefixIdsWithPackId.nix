{ pkgs, lib, ... }:
{
  id,
  stickers,
  ...
}:
  map (sticker: sticker // { id = "${id}-${sticker.id}"; }) stickers
