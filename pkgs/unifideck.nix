{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  zlib,
}:

let
  deckyPythonAbi = "cpython-314";
  wheelsWithoutPurePythonFallback = [
    "rpds"
    "rpds_py-*.dist-info"
  ];
  signatureFile = "py_modules/unifideck/core/binaries/binary_signatures.py";
  patchelfedBinaries = {
    nile = "bin/nile";
    butler = "bin/butler/butler";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "unifideck";
  version = "0.7.6";

  src = fetchurl {
    url = "https://github.com/mubaraknumann/unifideck/releases/download/Release-${finalAttrs.version}/unifideck.prod.v${finalAttrs.version}.zip";
    hash = "sha256-NsngV6IuLapfdAbaeJ6F2wOQBd4wfhYPclET8qOeYxU=";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    zlib
  ];

  sourceRoot = "Unifideck";
  dontBuild = true;
  dontStrip = true;
  autoPatchelfIgnoreMissingDeps = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  postInstall = ''
    find $out/py_modules -name '*.cpython-3??-x86_64-linux-gnu.so' \
      ! -name '*.${deckyPythonAbi}-*' -print -delete
    rm -rf ${
      lib.concatMapStringsSep " " (wheel: "$out/py_modules/${wheel}") wheelsWithoutPurePythonFallback
    }
  '';

  postPhases = [ "resignPatchelfedBinariesPhase" ];
  resignPatchelfedBinariesPhase = ''
    signatures=$out/${signatureFile}

    refreshSignature() {
      local name=$1 binary=$2 oldHash newHash
      oldHash=$(grep -A2 "\"$name\":" "$signatures" | grep -oE '[0-9a-f]{64}' | head -1)
      newHash=$(sha256sum "$binary" | cut -d' ' -f1)
      echo "$name: $oldHash -> $newHash"
      substituteInPlace "$signatures" --replace-fail "$oldHash" "$newHash"
    }

    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: path: "refreshSignature ${name} $out/${path}") patchelfedBinaries
    )}
  '';

  meta = {
    description = "Unified game library for Steam Deck and Steam Machine";
    homepage = "https://github.com/mubaraknumann/unifideck";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
  };
})
