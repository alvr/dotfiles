{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.nginx;

  realIPFrom = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
  fileToList = x: lib.strings.splitString "\n" (builtins.readFile x);
  cfIPv4 = fileToList (
    pkgs.fetchurl {
      url = "https://www.cloudflare.com/ips-v4";
      sha256 = "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
    }
  );
  cfIPv6 = fileToList (
    pkgs.fetchurl {
      url = "https://www.cloudflare.com/ips-v6";
      sha256 = "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
    }
  );

  oidcEnabled = lib.any (h: h.oidc != null) cfg.hosts;
  luaJson = value: "cjson.decode(${builtins.toJSON (builtins.toJSON value)})";
  appendConfig =
    existing: addition:
    lib.concatStringsSep "\n" (
      lib.filter (s: s != "") [
        existing
        addition
      ]
    );

  mkOidcLua =
    hostName: hostCfg: clientIdPath: clientSecretPath: sessionSecretPath:
    pkgs.writeText "oidc-${hostName}.lua" ''
      local cjson = require("cjson.safe")
      local openidc = require("resty.openidc")

      local public_paths = ${luaJson hostCfg.publicPaths}
      local uri = ngx.var.uri
      for _, p in ipairs(public_paths) do
        local prefix = p:gsub("/+$", "")
        if prefix ~= "" and (uri == prefix or uri:find(prefix .. "/", 1, true) == 1) then
          return
        end
      end

      local function read_secret(path)
        local f = io.open(path, "r")
        if not f then
          ngx.log(ngx.ERR, "OIDC: cannot read secret ", path)
          return nil
        end
        local val = f:read("*a")
        f:close()
        if not val then
          ngx.log(ngx.ERR, "OIDC: failed to read secret ", path)
          return nil
        end
        return (val:gsub("%s+$", ""))
      end

      local client_id = read_secret(${builtins.toJSON clientIdPath})
      local client_secret = read_secret(${builtins.toJSON clientSecretPath})
      local session_secret = read_secret(${builtins.toJSON sessionSecretPath})

      if
       	not client_id
       	or client_id == ""
       	or not client_secret
       	or client_secret == ""
       	or not session_secret
       	or session_secret == ""
      then
        ngx.log(ngx.ERR, "OIDC: missing client credentials, refusing to authenticate")
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
      end

      local function arg_str(v)
        if type(v) == "table" then
          v = v[1]
        end
        if type(v) == "string" then
          return v
        end
        return nil
      end

      local callback_path = "/oauth2/callback"
      local args = ngx.req.get_uri_args()
      if uri == callback_path and args.error then
        local detail = arg_str(args.error_description) or arg_str(args.error) or "authorization failed"
        ngx.status = ngx.HTTP_FORBIDDEN
        ngx.header.content_type = "text/plain"
        ngx.say("Access denied: " .. detail)
        ngx.exit(ngx.HTTP_FORBIDDEN)
      end

      local opts = {
        discovery = "https://id.${consts.domain}/.well-known/openid-configuration",
        client_id = client_id,
        client_secret = client_secret,
        scope = "openid profile email groups",
        ssl_verify = "yes",
        redirect_uri = "https://${hostName}.${consts.domain}" .. callback_path,
        use_pkce = true,
        prompt = "login",
      }
      local session_opts = {
        secret = session_secret,
        cookie_http_only = true,
        cookie_secure = true,
        cookie_same_site = "Lax",
      }

      local res, err = openidc.authenticate(opts, nil, nil, session_opts)
      if err then
        ngx.log(ngx.ERR, "OIDC auth error: ", err)
        ngx.exit(500)
      end
      if not res then
        ngx.log(ngx.ERR, "OIDC: authentication returned no result")
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
      end

      local groups = res.id_token and res.id_token.groups or {}
      if type(groups) == "string" then
        groups = { groups }
      elseif type(groups) ~= "table" then
        groups = {}
      end
      local allowed_groups = ${luaJson hostCfg.allowedGroups}
      local has_access = #allowed_groups == 0
      if not has_access then
        for _, g in ipairs(groups) do
          for _, a in ipairs(allowed_groups) do
            if g == a then
              has_access = true
              break
            end
          end
          if has_access then
            break
          end
        end
      end

      if not has_access then
        ngx.log(ngx.WARN, "OIDC: user not in allowed groups")
        ngx.exit(403)
      end
    '';
in
{
  options.dot.services.nginx = {
    enable = lib.mkEnableOption "Enable Nginx service";

    hosts = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            config = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = { };
            };
            subdomain = lib.mkOption {
              type = lib.types.str;
            };
            port = lib.mkOption {
              type = lib.types.port;
            };
            internal = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            oidc = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
                    allowedGroups = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                    };
                    publicPaths = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                    };
                  };
                }
              );
              default = null;
            };
          };
        }
      );
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      nginx = {
        enable = true;
        package = if oidcEnabled then pkgs.openresty else pkgs.nginxMainline;
        recommendedBrotliSettings = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        statusPage = true;

        resolver.addresses = [ "1.1.1.1" ];

        commonHttpConfig = ''
          ${realIPFrom cfIPv4}
          ${realIPFrom cfIPv6}

          set_real_ip_from 127.0.0.1;
          set_real_ip_from ::1;

          real_ip_header CF-Connecting-IP;
          real_ip_recursive on;

          proxy_buffers               4 512k;
          proxy_buffer_size           1024k;
          proxy_busy_buffers_size     1024k;
          large_client_header_buffers 8 32k;

          ${lib.optionalString oidcEnabled ''
            lua_ssl_verify_depth 5;
            lua_shared_dict discovery 1m;
            lua_shared_dict jwks 1m;
          ''}
        '';

        appendHttpConfig = ''
          map $http_cf_connecting_ip $client_real_ip {
            default $http_cf_connecting_ip;
            "" $remote_addr;
          }
        '';

        lua = lib.mkIf oidcEnabled {
          enable = true;
          extraPackages =
            ps: with ps; [
              lua-resty-http
              lua-resty-jwt
              lua-resty-openidc
              lua-resty-session
            ];
        };

        upstreams = lib.mkMerge (
          map (service: {
            "${service.subdomain}".servers."127.0.0.1:${toString service.port}" = { };
          }) cfg.hosts
        );

        virtualHosts = lib.mkMerge (
          map (
            service:
            let
              domain = "${service.subdomain}.${consts.domain}";
              baseVhost = {
                forceSSL = true;
                http3 = true;
                kTLS = true;
                quic = true;
                useACMEHost = consts.domain;
                locations."/".proxyPass = "http://${service.subdomain}";
              }
              // lib.optionalAttrs service.internal {
                extraConfig = ''
                  allow ${config.dot.services.tailscale.subnet};
                  allow ${consts.lanSubnet};
                  deny all;
                '';
              };
              configuredVhost = lib.recursiveUpdate baseVhost service.config;
            in
            {
              "${domain}" = lib.recursiveUpdate configuredVhost (
                lib.optionalAttrs (service.oidc != null) (
                  let
                    luaFile =
                      mkOidcLua service.subdomain service.oidc
                        config.sops.secrets."oidc/${service.subdomain}/client-id".path
                        config.sops.secrets."oidc/${service.subdomain}/client-secret".path
                        config.sops.secrets."oidc/session-secret".path;
                  in
                  {
                    extraConfig = appendConfig (configuredVhost.extraConfig or "") ''
                      access_by_lua_file ${luaFile};
                    '';
                  }
                )
              );
            }
          ) cfg.hosts
        );
      };

      tailscale.permitCertUid = "nginx";

      prometheus.exporters.nginx = lib.mkIf config.dot.services.prometheus.enable {
        enable = true;
        inherit (config.services.nginx) user group;
      };
    };

    dot = {
      services.prometheus.scrape.nginx = lib.mkIf config.dot.services.prometheus.enable {
        inherit (config.services.prometheus.exporters.nginx) port;
      };

      services.tailscale.internalDomains = map (service: "${service.subdomain}.${consts.domain}") (
        lib.filter (service: service.internal) cfg.hosts
      );

      system.persistence.directories = [
        {
          directory = "/var/lib/acme";
          user = "acme";
          group = "acme";
          mode = "u=rwx,g=r,o=";
        }
      ];
    };

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [ 443 ];
    };

    security.acme = {
      acceptTerms = true;

      defaults = {
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        inherit (consts) email;

        credentialFiles = {
          CF_DNS_API_TOKEN_FILE = config.sops.secrets."acme/cf-api-token".path;
        };
      };

      certs."${consts.domain}" = {
        inherit (consts) domain;
        extraDomainNames = [
          "*.${consts.domain}"
        ];
      };
    };

    sops.secrets = lib.mkMerge [
      {
        "acme/cf-api-token" = {
          sopsFile = ../../secrets/services/acme.yaml;
          owner = "acme";
          group = "acme";
          mode = "0400";
        };
      }
      (lib.mkIf oidcEnabled (
        let
          oidcSops = {
            sopsFile = ../../secrets/services/oidc.yaml;
            owner = "nginx";
            group = "nginx";
            mode = "0400";
            restartUnits = [ "nginx.service" ];
          };
          oidcHosts = lib.filter (h: h.oidc != null) cfg.hosts;
        in
        lib.mkMerge (
          [ { "oidc/session-secret" = oidcSops; } ]
          ++ map (host: {
            "oidc/${host.subdomain}/client-id" = oidcSops;
            "oidc/${host.subdomain}/client-secret" = oidcSops;
          }) oidcHosts
        )
      ))
    ];

    users.users.nginx.extraGroups = [ "acme" ];
  };
}
