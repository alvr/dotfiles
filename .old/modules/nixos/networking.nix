{ config, pkgs, ... }:
{
  sops.secrets.wifi = {
    owner = "root";
    group = "root";
    mode = "0400";
    restartUnits = [ "NetworkManager-ensure-profiles.service" ];
  };

  networking = {
    firewall.enable = true;

    networkmanager = {
      enable = true;
      wifi.backend = "iwd";

      ensureProfiles = {
        environmentFiles = [ config.sops.secrets.wifi.path ];

        profiles = {
          home-wifi = {
            connection = {
              id = "$SSID";
              type = "wifi";
              uuid = "bed12b7e-b230-4f68-870d-8ab0cf89eb26";
            };
            ipv4 = {
              method = "auto";
            };
            ipv6 = {
              addr-gen-mode = "default";
              method = "auto";
            };
            wifi = {
              mode = "infrastructure";
              ssid = "$SSID";
            };
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$PSK";
            };
          };
        };
      };
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
}
