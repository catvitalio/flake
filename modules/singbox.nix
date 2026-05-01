{
  lib,
  config,
  secrets,
  ...
}:

let
  cfg = config.my.singbox;
  hysteria2 = import "${secrets}/hysteria2.nix";
in
{
  options.my.singbox = {
    enable = lib.mkEnableOption "sing-box proxy via Hysteria2";

    mode = lib.mkOption {
      type = lib.types.enum [
        "tun"
        "socks"
      ];
      default = "tun";
      description = "Inbound mode. `tun` creates a TUN interface; `socks` exposes a SOCKS5 proxy.";
    };

    networkInterface = lib.mkOption {
      type = lib.types.str;
      description = "Interface to bind direct and hysteria2 outbounds to.";
    };

    socksListenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Listen address for the SOCKS5 inbound (mode=socks).";
    };

    socksListenPort = lib.mkOption {
      type = lib.types.port;
      default = 1080;
      description = "Listen port for the SOCKS5 inbound (mode=socks).";
    };

    tunInterface = lib.mkOption {
      type = lib.types.str;
      default = "singbox0";
      description = "Name of TUN interface created by sing-box.";
    };

    address = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "172.19.0.1/30"
        "fdfe:dcba:9876::1/126"
      ];
      description = "Addresses assigned to the TUN interface.";
    };

    strictRoute = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable strict routing in the tun inbound.";
    };

    autoRoute = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable auto_route in the tun inbound.";
    };

    autoRedirect = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable auto_redirect in the tun inbound.";
    };

    stack = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional tun stack setting (e.g. \"system\").";
    };

    routeExcludeAddress = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "10.100.0.0/24"
        "100.64.0.0/10"
        "169.254.0.0/16"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "::1/128"
        "fc00::/7"
        "fe80::/10"
      ];
      description = "Optional route_exclude_address list for tun inbound.";
    };

    directIpCidrs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "IP CIDRs that should bypass the proxy via outbound:direct.";
    };

    geoipRuRuleSetUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-ru.srs";
      description = "Remote SRS ruleset URL for geoip-ru.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.trustedInterfaces = lib.mkIf (cfg.mode == "tun") [ cfg.tunInterface ];

    services.sing-box = {
      enable = true;
      settings = {
        dns = {
          servers = [
            {
              type = "local";
              tag = "dns-direct";
            }
          ];
          final = "dns-direct";
        };

        inbounds =
          lib.optionals (cfg.mode == "tun") [
            (
              {
                type = "tun";
                tag = "inbound:tun";
                interface_name = cfg.tunInterface;
                inherit (cfg) address;
                auto_route = cfg.autoRoute;
                auto_redirect = cfg.autoRedirect;
                strict_route = cfg.strictRoute;
              }
              // lib.optionalAttrs (cfg.stack != null) { stack = cfg.stack; }
              // lib.optionalAttrs (cfg.routeExcludeAddress != [ ]) {
                route_exclude_address = cfg.routeExcludeAddress;
              }
            )
          ]
          ++ lib.optionals (cfg.mode == "socks") [
            {
              type = "socks";
              tag = "inbound:socks";
              listen = cfg.socksListenAddress;
              listen_port = cfg.socksListenPort;
            }
          ];

        outbounds = [
          {
            type = "direct";
            tag = "outbound:direct";
            bind_interface = cfg.networkInterface;
          }
          {
            type = "hysteria2";
            tag = "outbound:hy2";
            bind_interface = cfg.networkInterface;
            server = hysteria2.domain;
            server_port = 443;
            password = hysteria2.password;
            tls = {
              enabled = true;
              server_name = hysteria2.domain;
              alpn = [ "h3" ];
            };
          }
        ];

        route = {
          final = "outbound:hy2";
          default_interface = cfg.networkInterface;
          rules =
            lib.optionals (cfg.directIpCidrs != [ ]) [
              {
                ip_cidr = cfg.directIpCidrs;
                outbound = "outbound:direct";
              }
            ]
            ++ [
              {
                rule_set = "geoip-ru";
                outbound = "outbound:direct";
              }
            ];

          rule_set = [
            {
              type = "remote";
              tag = "geoip-ru";
              url = cfg.geoipRuRuleSetUrl;
              download_detour = "outbound:hy2";
              update_interval = "24h0m0s";
            }
          ];
        };
      };
    };
  };
}
