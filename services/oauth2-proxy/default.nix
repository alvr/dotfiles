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
in
{
  options.dot.services.oauth2-proxy = {
    enable = lib.mkEnableOption "Enable OAuth2 Proxy service";
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
        refresh = "30m";
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
