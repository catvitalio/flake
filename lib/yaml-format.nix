pkgs: {
  generate =
    value:
    pkgs.runCommand "config.yaml" { } ''
      sed -E 's/^([[:space:]]*)"([0-9]+)":/\1\2:/' \
        ${(pkgs.formats.yaml { }).generate "config-quoted.yaml" value} > $out
    '';
}
