{ pkgs, lib, ... }:

# This command takes a list of stickerType (see module.nix),
# and a bunch of other args in order to retrieve a bunch of
# stickers based on their url.
#
# It will put these as a single derivation in the nix store,
# update the properties of the stickers (in particular the "path")
# and then retrieve a list of stickerType.
#
# The stickers that already have a path will be ignored, and then
# all urls will be deleted.

{
  stickers,
  id,
  hash ? "",
  sha256 ? "",
  ...
}:
let
  inherit (pkgs.callPackage ../utils.nix { }) withDefaultAttr;

  stickerdir =
    let
      downloadCommands = lib.pipe stickers [
        (builtins.filter (sticker: !sticker ? "path" || sticker.path == null))
        (map ({ url, id, ... }: "curl -o $out/${id} \"${url}\""))
        (builtins.concatStringsSep "\n")
      ];
    in
      pkgs.runCommandLocal "maunium-stickerpack-${id}" {
        buildInputs = with pkgs; [ curl ];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

        outputHashAlgo = if hash != "" then null else "sha256";
        outputHashMode = "recursive";
        outputHash = if hash != "" then hash
        else if sha256 != "" then sha256
        else lib.fakeSha256;
      } ''
        mkdir -p $out
        ${downloadCommands}
      '';

  stickerNotFoundWarning = sticker: ''
    Could not find expected sticker at location: ${sticker.path};

    More info:
    ${builtins.toJSON sticker}
  '';
in
  lib.pipe stickers [
    (map (sticker: withDefaultAttr "path" "${stickerdir}/${sticker.id}" sticker))
    (map (sticker:
      assert lib.assertMsg
        (builtins.pathExists "${sticker.path}")
        (stickerNotFoundWarning sticker);
        sticker
    ))
    (map (sticker: builtins.removeAttrs sticker [ "url" ]))
  ]
