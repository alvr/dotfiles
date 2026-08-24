{ inputs, ... }:
{
  flake.modules.nixos.cloudflared =
    { config, lib, ... }:
    let
      cfg = config.dot.services.cloudflared;
      hostName = config.dot.host.name;
    in
    {
      options.dot.services.cloudflared = {
        subdomains = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };

      config = {
        services.cloudflared = {
          enable = true;
          certificateFile = config.sops.secrets.cloudflare-cert.path;

          tunnels.${hostName} = {
            credentialsFile = config.sops.secrets.cloudflare-tunnel.path;
            default = "http_status:404";

            ingress =
              let
                hostnames = map (subdomain: "${subdomain}.${config.dot.host.network.domain}") cfg.subdomains;
              in
              lib.genAttrs hostnames (hostname: {
                service = "https://localhost";
                originRequest = {
                  httpHostHeader = hostname;
                  originServerName = hostname;
                  noTLSVerify = false;
                };
              });
          };
        };

        sops.secrets =
          let
            cloudflare-secret = {
              format = "binary";
              mode = "0400";
              restartUnits = [ "cloudflared-tunnel-${hostName}.service" ];
            };
          in
          {
            cloudflare-cert = cloudflare-secret // {
              sopsFile = "${inputs.secrets}/${hostName}/services/cloudflared/cloudflare-cert";
            };

            cloudflare-tunnel = cloudflare-secret // {
              sopsFile = "${inputs.secrets}/${hostName}/services/cloudflared/cloudflare-tunnel";
            };
          };
      };
    };
}
