{
  lib,
  pkgs,
  protonCachyos,
}:
{
  name,
  displayName,
  exports ? { },
}:
pkgs.runCommand name
  {
    outputs = [
      "out"
      "steamcompattool"
    ];
  }
  ''
    mkdir -p "$steamcompattool"
    cp -r ${protonCachyos.steamcompattool}/. "$steamcompattool"/
    chmod -R u+w "$steamcompattool"

    if [ ! -f "$steamcompattool/proton" ]; then
      echo "proton launcher not found in ${protonCachyos.steamcompattool}" >&2
      exit 1
    fi

    mv "$steamcompattool/proton" "$steamcompattool/proton-real"

    cat > "$steamcompattool/proton" <<'EOF'
    #!/usr/bin/env bash
    set -euo pipefail

    script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "export ${k}=${lib.escapeShellArg v}") exports
    )}

    exec -a "$0" "$script_dir/proton-real" "$@"
    EOF

    chmod +x "$steamcompattool/proton"

    cat > "$steamcompattool/compatibilitytool.vdf" <<EOF
    "compatibilitytools"
    {
      "compat_tools"
      {
        "${name}"
        {
          "install_path" "."
          "display_name" "${displayName}"
          "from_oslist" "windows"
          "to_oslist" "linux"
        }
      }
    }
    EOF

    mkdir -p "$out"
    ln -s "$steamcompattool" "$out/steamcompattool"
  ''
