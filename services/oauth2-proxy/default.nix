{
  config,
  consts,
  lib,
  ...
}:
let
  cfg = config.dot.services.oauth2-proxy;

  subdomain = "auth";
  port = 4180;

  domainFor =
    name: if lib.hasSuffix ".${consts.domain}" name then name else "${name}.${consts.domain}";
in
{
  options.dot.services.oauth2-proxy = {
    enable = lib.mkEnableOption "Enable OAuth2 Proxy service";

    hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            allowed_groups = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Allowed groups for the protected virtual host.";
            };
          };
        }
      );
      default = { };
      description = "Nginx virtual hosts (subdomain -> groups) protected by oauth2-proxy.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.oauth2-proxy = {
      enable = true;
      clientID = "3bf55c96-903e-46f2-b94f-1e5455b77948";
      email.domains = [ "*" ];
      keyFile = config.sops.secrets."oauth2-proxy/env".path;
      nginx.domain = "${subdomain}.${consts.domain}";
      oidcIssuerUrl = "https://id.${consts.domain}";
      provider = "oidc";
      redirectURL = "https://${subdomain}.${consts.domain}/oauth2/callback";
      reverseProxy = true;
      scope = "openid profile email groups";
      setXauthrequest = true;

      cookie = {
        domain = ".${consts.domain}";
        refresh = "1h";
        secure = true;
      };

      extraConfig = {
        whitelist-domain = [
          consts.domain
          "*.${consts.domain}"
        ];
        insecure-oidc-allow-unverified-email = true;
        code-challenge-method = "S256";
        insecure-oidc-skip-nonce = false;
      };

      nginx.virtualHosts = lib.mapAttrs' (subdomainName: vhostCfg: {
        name = domainFor subdomainName;
        value = vhostCfg;
      }) cfg.hosts;
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      nginx.hosts = [
        { inherit subdomain port; }
      ];
    };

    sops.secrets."oauth2-proxy/env" = {
      sopsFile = ../../secrets/services/oauth2-proxy.yaml;
      owner = "oauth2-proxy";
      group = "oauth2-proxy";
      mode = "0400";
      restartUnits = [ "oauth2-proxy.service" ];
    };

    systemd.services.oauth2-proxy = {
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
