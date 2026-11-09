{
  stdenvNoCC,
  runCommand,
  resvg,
  ffmpeg,
  nixos-icons,

  logoSvg ? "${nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg",
  width ? 64,
  height ? 64,
  blurSigma ? 10.5,
  progressBarWidth ? 160,
  progressBarHeight ? 3,
  progressBarVerticalAlignment ? 0.6,
}:
assert width > 0 && height > 0 && blurSigma > 0;
assert builtins.isInt progressBarWidth && progressBarWidth > 0;
assert builtins.isInt progressBarHeight && progressBarHeight > 0;
assert progressBarVerticalAlignment >= 0.0 && progressBarVerticalAlignment <= 1.0;
let
  logoPng = runCommand "logo.png" { nativeBuildInputs = [ resvg ]; } ''
    resvg --width ${toString width} --height ${toString height} "${logoSvg}" "$out"
  '';
  glowPng = runCommand "glow.png" { nativeBuildInputs = [ ffmpeg ]; } ''
    ffmpeg -v error -i "${logoPng}" \
      -vf 'format=rgba,pad=iw+2*${toString glowPadding}:ih+2*${toString glowPadding}:(ow-iw)/2:(oh-ih)/2:color=black@0,geq=r=255:g=255:b=255:a=alpha(X\,Y),gblur=sigma=${toString blurSigma}:steps=2' \
      -frames:v 1 -f image2 -update 1 "$out"
  '';
  progressImages = runCommand "progress-images" { nativeBuildInputs = [ ffmpeg ]; } ''
    mkdir -p "$out"
    for item in trough:0x404040 fill:0xffffff; do
      ffmpeg -v error -f lavfi -i "color=c=''${item#*:}:s=2x2" \
        -vf 'format=rgba,scale=1:1' -frames:v 1 -f image2 -update 1 \
        "$out/progress-''${item%:*}.png"
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
    substituteInPlace "$theme/snowflake.script" \
      --replace-fail '@PROGRESS_BAR_WIDTH@' '${toString progressBarWidth}' \
      --replace-fail '@PROGRESS_BAR_HEIGHT@' '${toString progressBarHeight}' \
      --replace-fail '@PROGRESS_BAR_VERTICAL_ALIGNMENT@' '${toString progressBarVerticalAlignment}' \

    cp "${logoPng}" "$theme/logo.png"
    cp "${glowPng}" "$theme/glow.png"
    cp "${progressImages}"/*.png "$theme/"

    runHook postInstall
  '';
}
