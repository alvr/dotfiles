{ config, ... }:
{
  sops.secrets.tailscale-authkey = {
    restartUnits = [ "tailscaled.service" ];
  };

  services.tailscale = {
    enable = true;
    disableTaildrop = true;
    openFirewall = true;
    authKeyFile = config.sops.secrets.tailscale-authkey.path;
    useRoutingFeatures = "server";

    extraUpFlags = [
      "--advertise-routes=100.93.93.0/24"
    ];
  };

  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/tailscale"
    ];
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
}
