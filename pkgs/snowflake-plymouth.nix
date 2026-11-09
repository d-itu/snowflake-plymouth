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
}:
assert width > 0 && height > 0 && blurSigma > 0;
let
  logoPng = runCommand "logo.png" { nativeBuildInputs = [ resvg ]; } ''
    resvg --width ${toString width} --height ${toString height} "${logoSvg}" "$out"
  '';
  glowPng = runCommand "glow.png" { nativeBuildInputs = [ ffmpeg ]; } ''
    ffmpeg -v error -i "${logoPng}" \
      -vf 'format=rgba,pad=iw+2*${toString glowPadding}:ih+2*${toString glowPadding}:(ow-iw)/2:(oh-ih)/2:color=black@0,geq=r=255:g=255:b=255:a=alpha(X\,Y),gblur=sigma=${toString blurSigma}:steps=2' \
      -frames:v 1 -f image2 -update 1 "$out"
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

    theme="$themes/snowflake-pulse"
    mkdir -p "$theme"
    cp themes/snowflake-pulse/snowflake-pulse.plymouth.in "$theme/snowflake-pulse.plymouth"
    substituteInPlace "$theme/snowflake-pulse.plymouth" --replace-fail '@PLYMOUTH_THEME_PATH@' "$themes"
    cp themes/snowflake-pulse/snowflake-pulse.script "$theme/snowflake-pulse.script"
    cp "${logoPng}" "$theme/logo.png"
    cp "${glowPng}" "$theme/glow.png"

    theme="$themes/snowflake"
    mkdir -p "$theme"
    cp themes/snowflake/snowflake.plymouth.in "$theme/snowflake.plymouth"
    substituteInPlace "$theme/snowflake.plymouth" --replace-fail '@PLYMOUTH_THEME_PATH@' "$themes"
    cp "${logoPng}" "$theme/watermark.png"

    runHook postInstall
  '';
}
