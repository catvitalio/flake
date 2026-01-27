{ lib }:

lib.flatten [
  (import ./ai.nix)
  (import ./google.nix)
  (import ./telegram.nix)
  (import ./whatsapp.nix)
  (import ./discord.nix)
  (import ./torrents.nix)
  (import ./development.nix)
  (import ./misc.nix)
  (import ./kinopub.nix)
  (import ./hdrezka.nix)
  (import ./patreon.nix)
]
