{
  flake.modules.nixos.nextdns =
    { config, lib, ... }:
    let
      cfg = config.dot.services.nextdns;
      internalDomains = lib.attrByPath [ "dot" "services" "tailscale" "internalDomains" ] [ ] config;
      tailscaleEnabled = config.services.tailscale.enable;
      unboundEnabled = config.services.unbound.enable;
    in
    {
      options.dot.services.nextdns = {
        profile = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "NextDNS profile ID for this host (6 chars, from my.nextdns.io). Differs per host.";
          example = "abcdef";
        };

        fallbacks = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "1.1.1.1"
            "8.8.8.8"
            "9.9.9.9"
          ];
          description = "Plain-DNS fallbacks after 127.0.0.1/::1 in /etc/resolv.conf and Unbound forward-zone.";
        };
      };

      config = {
        assertions = [
          {
            assertion = cfg.profile != "";
            message = "dot.services.nextdns.profile must be set per host (NextDNS profile ID from my.nextdns.io).";
          }
        ];

        services.nextdns = {
          enable = true;
          arguments = [
            "-profile=${cfg.profile}"
            "-listen=localhost:53"
            "-cache-size=10MB"
            "-report-client-info"
            "-bogus-priv=false"
          ]
          ++ lib.optionals unboundEnabled (
            map (domain: "-forwarder=${domain}=127.0.0.1:5353") internalDomains
          )
          ++ lib.optionals tailscaleEnabled [
            "-forwarder=ts.net=100.100.100.100"
            "-forwarder=100.in-addr.arpa=100.100.100.100"
          ];
        };

        networking.nameservers = [
          "127.0.0.1"
          "::1"
        ]
        ++ cfg.fallbacks;

        networking.networkmanager.dns = "none";

        services = {
          resolved.enable = false;
          tailscale.extraUpFlags = lib.mkIf tailscaleEnabled [ "--accept-dns=false" ];

          unbound.settings = lib.mkIf unboundEnabled {
            server."do-not-query-localhost" = false;
            forward-zone = [
              {
                name = ".";
                forward-addr = [ "127.0.0.1@53" ] ++ cfg.fallbacks;
              }
            ];
          };
        };
      };
    };
}
