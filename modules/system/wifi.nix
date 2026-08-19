{ inputs, ... }:
{
  flake.modules.nixos.wifi =
    { config, ... }:
    let
      network = config.dot.host.network;
    in
    {
      networking.networkmanager = {
        wifi.backend = "iwd";

        ensureProfiles = {
          environmentFiles = [ config.sops.secrets.wifi.path ];

          profiles.home-wifi = {
            connection = {
              id = "$HOME_SSID";
              type = "wifi";
              uuid = "bed12b7e-b230-4f68-870d-8ab0cf89eb26";
            };
            ipv4 = inputs.self.lib.mkIpv4 network.gateway network.wifi.ipv4;
            ipv6 = {
              addr-gen-mode = "default";
              method = "auto";
            };
            wifi = {
              mode = "infrastructure";
              ssid = "$HOME_SSID";
            };
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$HOME_PASS";
            };
          };
        };
      };

      sops.secrets.wifi = {
        format = "dotenv";
        sopsFile = "${inputs.secrets}/common/wifi.env";
        mode = "0400";
        restartUnits = [ "NetworkManager-ensure-profiles.service" ];
      };
    };
}
