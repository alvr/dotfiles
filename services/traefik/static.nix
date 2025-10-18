{
  api = {
    dashboard = true;
    insecure = false;
  };

  certificatesResolvers = {
    letsencrypt.acme = {
      email = "alvaro@alvr.dev";
      storage = "/var/lib/traefik/cert.json";
      dnsChallenge.provider = "cloudflare";
    };
  };

  entryPoints = {
    web = {
      address = "0.0.0.0:80";
      http.redirections.entryPoint = {
        to = "websecure";
        scheme = "https";
        permanent = true;
      };
    };

    websecure = {
      address = "0.0.0.0:443";
      http.tls = {
        certResolver = "letsencrypt";
        domains = [
          {
            main = "alvr.dev";
            sans = [ "*.alvr.dev" ];
          }
        ];
      };
    };
  };

  global.sendAnonymousUsage = false;

  log = {
    level = "INFO";
    format = "common";
  };
}
