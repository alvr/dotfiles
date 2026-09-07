{ lib, ... }:
{
  flake.modules.nixos.fail2ban =
    { config, ... }:
    let
      cfg = config.dot.features.fail2ban;
      cfIps = config.dot.lib.cloudflare;
    in
    {
      options.dot.features.fail2ban.extraIgnoreIPs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra IPs/CIDRs appended to services.fail2ban.ignoreIP.";
      };

      config.services.fail2ban = {
        enable = true;

        bantime = "24h";
        bantime-increment = {
          enable = true;
          overalljails = true;
          maxtime = "720h";
          formula = "ban.Time * math.exp(float(ban.Count + 1) * banFactor) / math.exp(banFactor)";
        };

        maxretry = 3;

        ignoreIP = [
          # local
          "127.0.0.0/8"
          "192.168.0.0/16"
          "::1/128"
          "fe80::/10"
          "fc00::/7"
        ]
        ++ cfIps.ipv4
        ++ cfIps.ipv6
        ++ cfg.extraIgnoreIPs;
      };
    };
}
