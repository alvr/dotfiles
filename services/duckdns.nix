{ config, lib, ... }:
let
  cfg = config.dot.services.duckdns;
in
{
  options.dot.services.duckdns = {
    enable = lib.mkEnableOption "Enable DuckDNS service";
  };

  config = lib.mkIf cfg.enable {
    services.duckdns = {
      enable = true;
      domainsFile = config.sops.secrets."duckdns/domains".path;
      tokenFile = config.sops.secrets."duckdns/token".path;
    };

    sops.secrets = {
      "duckdns/domains" = {
        mode = "0400";
      };
      "duckdns/token" = {
        mode = "0400";
      };
    };
  };
}
