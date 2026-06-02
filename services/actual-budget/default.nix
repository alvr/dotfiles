{
  config,
  consts,
  lib,
  ...
}:
let
  cfg = config.dot.services.actual-budget;

  subdomain = "money";
  port = 27560;
in
{
  options.dot.services.actual-budget = {
    enable = lib.mkEnableOption "Enable Actual Budget service";
  };

  config = lib.mkIf cfg.enable {
    services.actual = {
      enable = true;
      settings = {
        inherit port;
        allowedLoginMethods = [ "openid" ];
        loginMethod = "openid";
        openId = {
          discoveryURL = "https://id.${consts.domain}";
          server_hostname = "https://${subdomain}.${consts.domain}";
          authMethod = "openid";
        };
      };
    };

    dot.services.nginx.hosts = [
      {
        inherit subdomain port;
        internal = true;
      }
    ];

    dot.system.persistence.directories = [
      "/var/lib/private/actual"
    ];

    systemd.services.actual = {
      requires = [
        "nginx.service"
        "pocket-id.service"
      ];
      after = [
        "nginx.service"
        "pocket-id.service"
      ];
    };
  };
}
