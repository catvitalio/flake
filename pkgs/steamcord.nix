{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  python3,
}:
let
  subprocessPython = python3.withPackages (ps: [
    ps.aiohttp
    ps.aiohttp-cors
    ps.pycairo
    ps.pygobject3
  ]);
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "steamcord";
  version = "1.42.2";

  src = fetchurl {
    url = "https://github.com/Necrosiak/Steamcord/releases/download/v${finalAttrs.version}/Steamcord.zip";
    hash = "sha256-lxhMEnwJSNFE+jwcURIaDFokhEl2SB2JNVqW5bI4B8I=";
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = "Steamcord";
  dontBuild = true;

  postPatch = ''
    rm -r gst-plugins

    substituteInPlace main.py \
      --replace-fail 'return _sh.which("python3") or _sh.which("python") or "/usr/bin/python"' \
                     'return "${subprocessPython}/bin/python3"'
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Discord voice chat, DMs and screen sharing inside Steam Game Mode";
    homepage = "https://github.com/Necrosiak/Steamcord";
    license = lib.licenses.bsd3;
    platforms = [ "x86_64-linux" ];
  };
})
