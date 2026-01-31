{ lib }:

lib.flatten [
  (import ./claude.nix)
  (import ./chatgpt.nix)
  (import ./google.nix)
  (import ./telegram.nix)
  (import ./whatsapp.nix)
  (import ./discord.nix)
  (import ./torrents.nix)
  (import ./zones.nix)
  (import ./misc.nix)
  (import ./kinopub.nix)
  (import ./hdrezka.nix)
  (import ./patreon.nix)
  (import ./nix.nix)
  (import ./raycast.nix)
  (import ./medium.nix)
]
