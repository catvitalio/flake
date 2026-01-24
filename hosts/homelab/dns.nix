{
  lib,
  ...
}:

let
  makeDomainPair = domain: [
    "/${domain}/10.100.0.100"
    "/${domain}/::"
  ];

  blockedDomains = [
    ".anthropic.com"
    ".claude.ai"
    ".claude.com"
    ".claudeusercontent.com"
    ".intercomcdn.com"
    ".intercom.help"
    ".claudemcpclient.com"

    ".chatgpt.com"
    ".chat.com"
    ".oaistatic.com"
    ".oaiusercontent.com"
    ".openai.com"
    ".sora.com"

    ".ytimg.com"
    ".googlevideo.com"
    ".gstatic.com"
    ".googleapis.com"
    ".youtube.com"
    ".yt.com"
    ".google.com"
    ".googleusercontent.com"
    ".gstatic.com"
    ".googleapis.com"
    ".youtube.com"
    ".yt.com"
    ".google.com"
    ".googleusercontent.com"
    ".gvt1.com"
    ".gvt2.com"
    ".googleplay.com"
    ".ggpht.com"

    ".cdn-telegram.org"
    ".comments.app"
    ".contest.com"
    ".fragment.com"
    ".graph.org"
    ".quiz.directory"
    ".t.me"
    ".tdesktop.com"
    ".telega.one"
    ".telegra.ph"
    ".telegram-cdn.org"
    ".telegram.dog"
    ".telegram.me"
    ".telegram.org"
    ".telegram.space"
    ".telesco.pe"
    ".tg.dev"
    ".tx.me"
    ".usercontent.dev"

    ".wa.me"
    ".whatsapp-plus.info"
    ".whatsapp-plus.me"
    ".whatsapp-plus.net"
    ".whatsapp.cc"
    ".whatsapp.com"
    ".whatsapp.info"
    ".whatsapp.net"
    ".whatsapp.org"
    ".whatsapp.tv"
    ".whatsappbrand.com"

    ".dis.gd"
    ".discord.co"
    ".discord.com"
    ".discord.design"
    ".discord.dev"
    ".discord.gg"
    ".discord.gift"
    ".discord.gifts"
    ".discord.media"
    ".discord.new"
    ".discord.store"
    ".discord.tools"
    ".discordapp.com"
    ".discordapp.net"
    ".discordmerch.com"
    ".discordpartygames.com"
    ".discord-activities.com"
    ".discordactivities.com"
    ".discordsays.com"
    ".website-files.com"

    ".rutracker.org"
    ".rutrk.org"
    ".rutracker.cc"

    ".patreon.com"
    ".patreonusercontent.com"
    ".patreoncommunity.com"

    ".anytype.io"

    ".medium.com"
    ".speedtest.net"
    ".discourse-cdn.com"
    "wiki.nixos.org"
    ".nix.dev"
    ".mynixos.com"
    ".localizeapi.com"
    ".alternativeto.net"
    ".culturedcode.com"
    ".ziffstatic.com"
    ".cloudfront.net"
    ".tableplus.com"
    ".wiki"
    ".sh"
    ".rs"
    ".ee"
    ".be"
    ".zone"
  ];

  blockedAddresses = lib.flatten (map makeDomainPair blockedDomains);
in
{
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      listen-address = "0.0.0.0";
      bind-interfaces = true;
      port = 53;
      server = [
        "77.88.8.8"
        "77.88.8.1"
      ];
      address = blockedAddresses ++ [
        "/nextcloud.catvitalio.com/10.100.0.2"
        "/bitwarden.catvitalio.com/10.100.0.2"
      ];
      cache-size = 10000;
    };
  };
}
