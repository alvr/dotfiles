{ config, lib, ... }:
let
  cfg = config.dot.services.duckdns;
in
{
  options.dot.services.duckdns = {
    enable = lib.mkEnableOption "Enable DuckDNS service" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "duckdns/domains" = { };
      "duckdns/token" = { };
    };

    services.duckdns = {
      enable = true;
      domainsFile = config.sops.secrets."duckdns/domains".path;
      tokenFile = config.sops.secrets."duckdns/token".path;
    };
  };
}
