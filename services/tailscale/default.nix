{ config, lib, ... }:
let
  cfg = config.dot.services.tailscale;
in
{
  options.dot.services.tailscale = {
    enable = lib.mkEnableOption "Enable Tailscale service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets.tailscale-authkey.path;
        disableTaildrop = true;
        useRoutingFeatures = "server";

        extraUpFlags = [ "--advertise-routes=100.93.93.0/24" ];
      };

      unbound = {
        enable = true;
        resolveLocalQueries = false;

        settings = {
          server = {
            interface = [ "${config.services.tailscale.interfaceName}" ];
            access-control = [ "100.93.93.0/24 allow" ];

            local-zone = [ ''"int.alvr.dev." redirect'' ];
            local-data = [ ''"int.alvr.dev. IN A 100.93.93.1"'' ];
            local-data-ptr = [ ''"100.93.93.1 int.alvr.dev"'' ];
          };
        };
      };
    };

    dot.system.persistence.directories = [ "/var/lib/tailscale" ];

    networking.firewall = {
      allowedTCPPorts = [ config.services.tailscale.port ];
      allowedUDPPorts = [ config.services.tailscale.port ];
      trustedInterfaces = [ "tailscale0" ];

      interfaces."${config.services.tailscale.interfaceName}" = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };
    };

    sops.secrets.tailscale-authkey = {
      mode = "0400";
      restartUnits = [ "tailscaled.service" ];
    };

    systemd.services.tailscaled = {
      after = [
        "network-online.target"
        "systemd-resolved.service"
      ];
      wants = [
        "network-online.target"
        "systemd-resolved.service"
      ];
    };
  };
}
