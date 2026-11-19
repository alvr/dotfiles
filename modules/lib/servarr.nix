{ inputs, ... }:
{
  config.flake.lib.mkArr =
    { name, port }:
    { config, lib, ... }:
    let
      allowedHosts = lib.concatStringsSep "," [
        "${name}.${config.dot.host.network.domain}"
        "localhost"
        "127.0.0.1"
      ];
    in
    {
      services = {
        ${name} = {
          enable = true;
          dataDir = "/var/lib/${name}";
          settings.server = {
            inherit port;
            inherit allowedHosts;
          };
        };

        prometheus.exporters."exportarr-${name}" = lib.mkIf config.services.prometheus.enable {
          enable = true;
          apiKeyFile = config.sops.secrets."${name}/api-key".path;
          port = port + 1;
          url = "http://localhost:${toString port}";
          user = config.services.${name}.user;
          group = config.services.${name}.group;
        };
      };

      dot.services = {
        nginx.hosts = [
          {
            subdomain = name;
            inherit port;
            internal = true;
            config.locations."/".proxyWebsockets = true;

            oidc.allowedGroups = [ "${name}_users" ];
          }
        ];

        prometheus.scrape.${name} = lib.mkIf config.services.prometheus.enable {
          inherit (config.services.prometheus.exporters."exportarr-${name}") port;
        };
      };

      dot.system.persistence.directories = [
        {
          directory = "/var/lib/${name}";
          user = name;
          group = name;
          mode = "u=rwx,g=,o=";
        }
      ];

      sops.secrets."${name}/api-key" = lib.mkIf config.services.prometheus.enable {
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/${name}.yaml";
        owner = name;
        group = name;
        mode = "0400";
        restartUnits = [ "prometheus-exportarr-${name}-exporter.service" ];
      };

      systemd.services."prometheus-exportarr-${name}-exporter" =
        lib.mkIf config.services.prometheus.enable
          {
            requires = [
              "${name}.service"
              "prometheus.service"
            ];
            after = [
              "${name}.service"
              "prometheus.service"
            ];
          };

      systemd.tmpfiles.rules = [
        "d /var/lib/${name} 0700 ${name} ${name} -"
      ];

      users.groups.media = { };
      users.users.${name}.extraGroups = [ "media" ];
    };
}
