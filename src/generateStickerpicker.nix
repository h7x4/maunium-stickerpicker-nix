{ pkgs, lib, stdenvNoCC, mauniumStickerpicker, pipes }:
{
  instanceName, # str
  stickerMatrixDomain, # str
  realMatrixDomain, # str
  stickerPacks, # listOf { title: str, id: str, stickers: see module.nix, }
  ...
}: let
  inherit (pkgs.callPackage ./utils.nix { }) withDefaultAttr;
  applyStickerPipe = pipe: editArgs: stickerPacks:
    map (pack: pack // { stickers = pipe (editArgs pack); }) stickerPacks;

  # packsWithIds :: listOf ({ title: str, id: str, stickers: attrs }})
  packsWithIds = lib.pipe stickerPacks (with pipes; [
    (applyStickerPipe assignIds (pack: pack))
    (applyStickerPipe prefixIdsWithPackId (pack: pack))
  ]);

  # processedPacks :: listOf ({ title: str, id: str, stickers: attrs }})
  preProcessedPacks = lib.pipe packsWithIds (with pipes; [
    (applyStickerPipe assignTitles (pack: pack // { titlePrefix = pack.title; }))
    (applyStickerPipe autoFetcher (pack: pack)) # Guaranteed "path"
    (applyStickerPipe imagemagickConverter (pack: pack))
    (applyStickerPipe mediainfoExtractor (pack: pack))
    (map (pack: withDefaultAttr "title" pack.id pack))
  ]);

  # processedPacks :: listOf ({ title: str, id: str, stickers: attrs }})
  processedPacks =
    applyStickerPipe pipes.generateStickerpack (pack: {
      inherit (pack) stickers id title;
      domain = stickerMatrixDomain;
    }) preProcessedPacks;

  # environmentSafeNames :: attrsOf str
  environmentSafeNames = let
    mapAttrVals = f: builtins.mapAttrs (_: f);
  in lib.pipe packsWithIds [
    (map (pack: lib.nameValuePair pack.id pack.id))
    builtins.listToAttrs
    # NOTE: Yeah, this is lossy, but I don't think it's a problem at the momemt.
    #       It's an internal detail and won't be exposed in the resulting realized
    #       derivaiton, so it can be changed later without any harm.
    (mapAttrVals (i: builtins.replaceStrings ["-" "."] ["_" "_"] i))
    (mapAttrVals lib.toUpper)
  ];

  # finalPacks :: attrsOf (listOf attrs)
  finalPacks = lib.pipe processedPacks [
    (map (pack: pack // { stickers = builtins.toJSON pack.stickers; }))
    (map (pack: lib.nameValuePair environmentSafeNames.${pack.id} pack.stickers))
    builtins.listToAttrs
  ];

  # stickerpackIndex :: str
  stickerpackIndex = lib.pipe packsWithIds [
    (map (pack: "${pack.id}.json"))
    (packs: {
      inherit packs;
      homeserver_url = "https://${realMatrixDomain}";
    })
    builtins.toJSON
  ];

  # moveStickerpackIndexCommands :: str
  moveStickerpackIndexCommands = lib.pipe environmentSafeNames [
    (lib.mapAttrsToList (name: value: ''mv ''$${value}Path $out/packs/${name}.json''))
    (builtins.concatStringsSep "\n")
  ];
in
stdenvNoCC.mkDerivation ({
  name = "maunium-stickerpicker-${instanceName}";
  src = mauniumStickerpicker;

  dontBuild = true;

  "INDEX_JSON" = stickerpackIndex;
  passAsFile = [ "INDEX_JSON" ] ++ (builtins.attrValues environmentSafeNames);

  passthru.stickerPacks = preProcessedPacks;

  installPhase = ''
    cp -r web $out
    cp $INDEX_JSONPath $out/packs/index.json

    ${moveStickerpackIndexCommands}
  '';
} // finalPacks)
