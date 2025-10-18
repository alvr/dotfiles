{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.traefik;
in
{
  disabledModules = [
    "services/web-servers/traefik.nix"
  ];

  imports = [
    (inputs.nixpkgs-unstable + "/nixos/modules/services/web-servers/traefik.nix")
  ];

  options.dot.services.traefik = {
    enable = lib.mkEnableOption "Enable Traefik service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      tailscale.permitCertUid = "traefik";

      traefik = {
        enable = true;
        environmentFiles = [ config.sops.secrets.traefik.path ];
        package = pkgs.unstable.traefik;

        dynamicConfigOptions = import ./dynamic.nix;
        staticConfigOptions = import ./static.nix;
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/traefik";
        user = "traefik";
        group = "traefik";
        mode = "u=rwx,g=,o=";
      }
    ];

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    sops.secrets.traefik = {
      format = "dotenv";
      sopsFile = ../../secrets/services/traefik.env;
      owner = "traefik";
      group = "traefik";
      mode = "0400";
      restartUnits = [ "traefik.service" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/traefik 0700 traefik traefik -"
      "f /var/lib/traefik/cert.json 0600 traefik traefik -"
    ];
  };
}
