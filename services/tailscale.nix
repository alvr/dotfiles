{ config, pkgs, ... }:
{
  sops.secrets.tailscale-authkey = {
    restartUnits = [ "tailscaled.service" ];
  };

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
