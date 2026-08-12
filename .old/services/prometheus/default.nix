{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.services.prometheus;

  port = 9090;
in
{
  options.dot.services.prometheus = {
    enable = lib.mkEnableOption "Enable Prometheus service";

    scrape = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            metrics_path = lib.mkOption {
              type = lib.types.str;
              default = "/metrics";
            };

            port = lib.mkOption {
              type = lib.types.port;
            };

            basic_auth = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
                    username = lib.mkOption {
                      type = lib.types.str;
                    };

                    password_file = lib.mkOption {
                      type = lib.types.path;
                    };
                  };
                }
              );
              default = null;
            };

            bearer_token_file = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
            };
          };
        }
      );
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      prometheus = {
        enable = true;
        checkConfig = "syntax-only";
        extraFlags = [ "--web.enable-otlp-receiver" ];
        inherit port;

        scrapeConfigs = lib.mapAttrsToList (
          name: scrapeCfg:
          {
            inherit (scrapeCfg) metrics_path;
            job_name = name;
            static_configs = [
              {
                targets = [ "localhost:${toString scrapeCfg.port}" ];
              }
            ];
          }
          // lib.optionalAttrs (scrapeCfg.basic_auth != null) {
            basic_auth = {
              inherit (scrapeCfg.basic_auth) username password_file;
            };
          }
          // lib.optionalAttrs (scrapeCfg.bearer_token_file != null) {
            inherit (scrapeCfg) bearer_token_file;
          }
        ) cfg.scrape;
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/prometheus2";
        user = "prometheus";
        group = "prometheus";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/prometheus2 0700 prometheus prometheus -"
    ];
  };
}
