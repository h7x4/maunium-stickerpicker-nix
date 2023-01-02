{ pkgs, lib, ... }: let
  baseFetcher = { instructions, type, title, id ? "", dir }: let
    dirname = "${type}-${dir}";
  in ''
    pushd $IMG_DIR
    mkdir '${dirname}'
    pushd '${dirname}'

    ${instructions}

    popd

    sticker-pack \
      --config "$STICKER_CONFIG" \
      --add-to-index "$STICKERPACKS_DIR" \
      --title '${title}' \
      '${dirname}'

    popd
  '';
in {
  directory-deps = [ ];
  directory-build = { src, id ? "", title ? "", ... }: baseFetcher {
    inherit id title;
    type = "directory";
    dir = builtins.baseNameOf src;
    instructions = ''
      ln -s ${src}/* .
    '';
  };

  chatsticker-deps = with pkgs; [ wget html-xml-utils ];
  chatsticker-build = { name, id ? "", title ? "", ... }: baseFetcher {
    inherit id title;
    type = "chatstickers";
    dir = name;
    instructions = ''
      wget "https://chatsticker.com/sticker/${name}" -O raw.html
      hxnormalize -l 240 -x raw.html > normalized.html
      cat normalized.html | hxselect -s '\n' -c ".img-fluid::attr(src)" > images.txt;
      sed -i 's|;compress=true||' images.txt

      for url in $(cat images.txt); do
        wget $url
      done

      rm raw.html normalized.html images.txt
    '';
  };
}
