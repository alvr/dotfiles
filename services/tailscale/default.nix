{
  config,
  consts,
  lib,
  ...
}:
let
  cfg = config.dot.services.tailscale;

  tailnetSubnet = "100.93.93.0/24";
  tailnetIp = "100.93.93.1";
in
{
  options.dot.services.tailscale = {
    enable = lib.mkEnableOption "Enable Tailscale service";

    internalDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets.tailscale-authkey.path;
        disableTaildrop = true;
      };

      unbound = {
        enable = true;
        resolveLocalQueries = false;

        settings.server = {
          access-control = [ "${tailnetSubnet} allow" ];

          local-data = map (domain: ''"${domain}. IN A ${tailnetIp}"'') cfg.internalDomains;

          interface = [
            tailnetIp
            "127.0.0.1"
          ];
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
