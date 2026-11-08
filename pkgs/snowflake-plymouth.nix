{
  stdenvNoCC,
  inkscape,
  chromium,
  python3,
}:
stdenvNoCC.mkDerivation {
  pname = "snowflake-plymouth";
  version = "1.0";

  src = ../.;
  nativeBuildInputs = [
    inkscape
    chromium
    (python3.withPackages (ps: [ ps.playwright ]))
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_CACHE_HOME="$HOME/.cache"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"

    theme="$out/share/plymouth/themes/snowflake"
    mkdir -p "$theme/resources"
    cp src/snowflake.plymouth "$theme/snowflake.plymouth"
    substituteInPlace "$theme/snowflake.plymouth" \
      --replace-fail /usr/share/ "$out/share/"

    for icon in bullet entry lock; do
      inkscape "resources/$icon.svg" \
        --export-filename="$theme/resources/$icon.png"
    done
    inkscape resources/caps-lock.svg \
      --export-filename="$theme/resources/capslock.png"

    python tools/render-svg-frames/render-svg-frames.py \
      resources/nixos-logo-animated.svg "$theme/resources" \
      "${chromium}/bin/chromium"

    runHook postInstall
  '';
}
