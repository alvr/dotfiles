{ self, ... }:
{
  flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      network = config.dot.host.network;
    in
    {
      networking = {
        hostName = config.dot.host.name;
        domain = lib.mkIf (network.domain != null) network.domain;

        firewall.enable = true;

        networkmanager = {
          enable = true;

          ensureProfiles.profiles = lib.mapAttrs (name: interface: {
            connection = {
              id = name;
              type = "ethernet";
              interface-name = name;
            };
            ipv4 = self.lib.mkIpv4 network.gateway interface.ipv4;
            ipv6.method = "auto";
          }) network.interfaces;
        };
      };

      systemd.services.NetworkManager-wait-online = {
        serviceConfig = {
          ExecStart = [
            ""
            "${pkgs.networkmanager}/bin/nm-online -q"
          ];
        };
      };
    };
}
