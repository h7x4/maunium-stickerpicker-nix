{
  lib,
  maunium-stickerpicker,
  stickerpicker-tools,
  fetchers,

  callPackage,
  stdenvNoCC,
  writeText,

  cacert,
  ...
}:
{
  homeserver ? "https://matrix.org",
  userId,
  accessTokenFile,
  packs,
  hash ? "",
  sha256 ? ""
}:
with lib;
if !(all builtins.isAttrs packs) then
  throw "createStickerPack: not all packs are attrsets"
else if !(all (x: x ? "type") packs) then
  throw ''createStickerPack: Not all packs have the "type" attribute''
else if !(all (x: builtins.isString x.type) packs) then
  throw ''createStickerPack: Not all packs have a "type" attribute of type string''
else let 
  invalidTypes = filter (x: !(fetchers ? "${x.type}-build")) packs;
in if invalidTypes != [ ] then throw ''
  createStickerPack: Not all packs have a valid "type" attribute.

  The following types does not exist:
  ${concatStringsSep "\n" (map (x: "  ${x.type}") invalidTypes)}
''
else let
  stickerDownloadInstructions = pipe packs [
    (map (x: fetchers."${x.type}-build" x))
    (concatStringsSep "\n")
  ];

  stickerDownloadDependencies = pipe packs [
    (map (x: fetchers."${x.type}-deps"))
    builtins.concatLists
  ];

  config-json = writeText "stickerpicker-config.json" ''
    {
      "homeserver": "${homeserver}",
      "user_id": "${userId}",
      "access_token": "${fileContents accessTokenFile}"
    }
  '';
in stdenvNoCC.mkDerivation {
  name = "stickerpicker";
  src = maunium-stickerpicker;

  outputHashAlgo = if hash != "" then null else "sha256";
  outputHashMode = "recursive";
  outputHash = if hash != "" then
    hash
  else if sha256 != "" then
    sha256
  else
    fakeSha256;

  buildInputs = [
    stickerpicker-tools
    cacert
  ] ++ stickerDownloadDependencies;

  buildPhase = ''
    mkdir images
    IMG_DIR="$(pwd)/images"
    STICKERPACKS_DIR="$(pwd)/web/packs"
    STICKER_CONFIG="${config-json}"

    ${stickerDownloadInstructions}
  '';

  installPhase = ''
    mv web $out
  '';
}
