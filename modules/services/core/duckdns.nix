{
  flake.modules.nixos.duckdns = { config, ... }: {
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

    systemd.services.duckdns = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
  };
}
