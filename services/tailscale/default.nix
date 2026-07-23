{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.services.tailscale;
in
{
  options.dot.services.tailscale = {
    enable = lib.mkEnableOption "Enable Tailscale service";

    internalDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "100.93.93.1";
      description = "This host's Tailscale IPv4 address, used to bind internal-only services to the tailnet interface.";
    };

    subnet = lib.mkOption {
      type = lib.types.str;
      default = "100.93.93.0/24";
      description = "The tailnet's IPv4 subnet, used to allow-list internal-only services for tailnet clients.";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets.tailscale-authkey.path;
        disableTaildrop = true;
        useRoutingFeatures = "server";
        extraUpFlags = [ "--advertise-routes=${cfg.subnet}" ];
      };

      unbound = {
        enable = true;
        resolveLocalQueries = false;

        settings.server = {
          access-control = [ "${cfg.subnet} allow" ];

          local-data = map (domain: ''"${domain}. IN A ${cfg.address}"'') cfg.internalDomains;

          interface = [
            cfg.address
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
