{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.tailscale;
in
{
  options.dot.services.tailscale = {
    enable = lib.mkEnableOption "Enable Tailscale service";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale-authkey.path;
      disableTaildrop = true;
      openFirewall = true;
      package = pkgs.unstable.tailscale;
      useRoutingFeatures = "server";

      extraUpFlags = [
        "--advertise-routes=100.93.93.0/24"
      ];
    };

    dot.system.persistence.directories = [
      "/var/lib/tailscale"
    ];

    networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];

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
