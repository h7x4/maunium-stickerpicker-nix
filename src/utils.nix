{ pkgs, lib, ... }:
{
  withDefaultAttr = attrName: value: attrs:
    attrs // {
      ${attrName} =
        if builtins.hasAttr attrName attrs && attrs.${attrName} != null
          then attrs.${attrName}
          else value;
    };
}