{
  stdenvNoCC,
  runCommand,
  resvg,
  ffmpeg,
  nixos-icons,

  logoSvg ? "${nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg",
  scaleLogo ? true,
  width ? 384,
  height ? 384,
  blurSigma ? 24,
  glowPadding ? builtins.ceil (blurSigma * 2),
}:
assert width > 0 && height > 0 && blurSigma > 0;
assert builtins.isBool scaleLogo;
let
  logoPng = runCommand "logo.png" { nativeBuildInputs = [ resvg ]; } ''
    resvg --width ${toString width} --height ${toString height} "${logoSvg}" "$out"
  '';
  glowPng = runCommand "glow.png" { nativeBuildInputs = [ ffmpeg ]; } ''
    ffmpeg -v error -i "${logoPng}" \
      -vf 'format=rgba,pad=iw+2*${toString glowPadding}:ih+2*${toString glowPadding}:(ow-iw)/2:(oh-ih)/2:color=black@0,geq=r=255:g=255:b=255:a=alpha(X\,Y),gblur=sigma=${toString blurSigma}:steps=2' \
      -frames:v 1 -f image2 -update 1 "$out"
  '';
  progressImages =
    runCommand "progress-images"
      {
        nativeBuildInputs = [
          resvg
          ffmpeg
        ];
      }
      ''
        mkdir -p "$out"
        for item in trough:404040 fill:ffffff; do
          name="''${item%:*}"
          substitute ${../themes/snowflake/progress.svg.in} "$TMPDIR/progress.svg" \
            --replace-fail '@COLOR@' "#''${item#*:}"
          resvg "$TMPDIR/progress.svg" "$TMPDIR/progress.png"
          if [ "$name" = fill ]; then
            cp "$TMPDIR/progress.png" "$out/progress-fill-short.png"
          fi
          ffmpeg -v error -i "$TMPDIR/progress.png" -vf 'format=rgba,crop=16:32:0:0' \
            -frames:v 1 -f image2 -update 1 "$out/progress-$name-left.png"
          ffmpeg -v error -i "$TMPDIR/progress.png" -vf 'format=rgba,crop=1:1:32:16' \
            -frames:v 1 -f image2 -update 1 "$out/progress-$name-center.png"
          ffmpeg -v error -i "$TMPDIR/progress.png" -vf 'format=rgba,crop=16:32:48:0' \
            -frames:v 1 -f image2 -update 1 "$out/progress-$name-right.png"
        done
      '';
in
stdenvNoCC.mkDerivation {
  pname = "snowflake-plymouth";
  version = "1.0";

  src = ../.;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    themes="$out/share/plymouth/themes"

    theme="$themes/snowflake"
    mkdir -p "$theme"
    cp themes/snowflake/snowflake.plymouth.in "$theme/snowflake.plymouth"
    substituteInPlace "$theme/snowflake.plymouth" --replace-fail '@PLYMOUTH_THEME_PATH@' "$themes"
    cp themes/snowflake/snowflake.script "$theme/snowflake.script"
    substituteInPlace "$theme/snowflake.script" --replace-fail '@SCALE_LOGO@' '${
      if scaleLogo then "1" else "0"
    }'

    cp "${logoPng}" "$theme/logo.png"
    cp "${glowPng}" "$theme/glow.png"
    cp "${progressImages}"/*.png "$theme/"

    runHook postInstall
  '';
}
