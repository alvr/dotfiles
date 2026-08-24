{
  flake.modules.nixos.actual-budget =
    { config, ... }:
    let
      subdomain = "money";
      port = 27560;
    in
    {
      services.actual = {
        enable = true;
        settings = {
          inherit port;
          allowedLoginMethods = [ "openid" ];
          loginMethod = "openid";
          openId = {
            discoveryURL = "https://id.${config.dot.host.network.domain}";
            server_hostname = "https://${subdomain}.${config.dot.host.network.domain}";
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
