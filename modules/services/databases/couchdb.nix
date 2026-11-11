{ inputs, ... }:
{
  flake.modules.nixos.couchdb =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      subdomain = "couchdb";
      port = 5984;

      vaults = {
        obsidian-user-1 = [
          "personal"
        ];
        obsidian-user-2 = [
          "personal"
          "studying"
        ];
      };

      secretFor = user: config.sops.templates."couchdb/users/${user}".path;
    in
    {
      services.couchdb = {
        enable = true;
        inherit port;

        extraConfigFiles = [ config.sops.templates."couchdb-admins.ini".path ];

        extraConfig = {
          couchdb = {
            single_node = true;
            max_document_size = 50000000;
          };

          chttpd = {
            require_valid_user = true;
            enable_cors = true;
            max_http_request_size = 4294967296;
          };

          chttpd_auth.require_valid_user = true;

          httpd = {
            enable_cors = true;
            "WWW-Authenticate" = ''Basic realm="couchdb"'';
          };

          cors = {
            origins = "app://obsidian.md,capacitor://localhost,http://localhost";
            credentials = true;
            headers = "accept, authorization, content-type, origin, referer";
            methods = "GET, PUT, POST, HEAD, DELETE";
            max_age = 3600;
          };
        };
      };

      dot.services = {
        cloudflared.subdomains = [ subdomain ];
        nginx.hosts = [
          {
            inherit subdomain port;
            config.extraConfig = "client_max_body_size 50M;";
          }
        ];
      };

      dot.system.persistence.directories = [
        {
          directory = "/var/lib/couchdb";
          user = "couchdb";
          group = "couchdb";
          mode = "u=rwx,g=,o=";
        }
      ];

      sops =
        let
          couchdbDefaults = {
            owner = "couchdb";
            group = "couchdb";
            mode = "0400";
            restartUnits = [ "couchdb.service" ];
          };
          secretFile = {
            sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/couchdb.yaml";
          };
        in
        {
          secrets = {
            "couchdb/admin" = couchdbDefaults // secretFile;
          }
          // builtins.listToAttrs (
            lib.concatMap (user: [
              {
                name = "couchdb/users/${user}/username";
                value = couchdbDefaults // secretFile;
              }
              {
                name = "couchdb/users/${user}/password";
                value = couchdbDefaults // secretFile;
              }
            ]) (builtins.attrNames vaults)
          );

          templates = {
            "couchdb-admins.ini" = couchdbDefaults // {
              content = ''
                [admins]
                ${config.sops.placeholder."couchdb/admin"}
              '';
            };
          }
          // builtins.listToAttrs (
            map (user: {
              name = "couchdb/users/${user}";
              value = couchdbDefaults // {
                content = ''
                  ${config.sops.placeholder."couchdb/users/${user}/username"}
                  ${config.sops.placeholder."couchdb/users/${user}/password"}
                '';
              };
            }) (builtins.attrNames vaults)
          );
        };

      systemd.services.couchdb = {
        path = with pkgs; [
          coreutils
          curl
          jq
        ];
        postStart =
          let
            base = "http://localhost:${toString port}";
          in
          ''
            set -euo pipefail

            admin_line="$(${pkgs.gnugrep}/bin/grep -v '^\[' ${
              config.sops.secrets."couchdb/admin".path
            } | head -n1)"
            admin_user="''${admin_line%% = *}"
            admin_pass="''${admin_line#* = }"
            [ -n "$admin_user" ] && [ "$admin_pass" != "$admin_line" ] || {
              echo "Malformed CouchDB admin credentials" >&2
              exit 1
            }
            auth="$admin_user:$admin_pass"

            # Wait until CouchDB is ready to accept authenticated requests.
            for _ in $(seq 1 60); do
              if curl -fsS -u "$auth" "${base}/_up" >/dev/null 2>&1; then
                break
              fi
              sleep 1
            done

            # Ensure the system databases exist (idempotent).
            for db in _users _replicator _global_changes; do
              curl -fsS -u "$auth" -X PUT "${base}/$db" >/dev/null 2>&1 || true
            done

            provision_user() {
              { read -r user; read -r pass; } < "$1"
              shift
              if [ "$user" = "$admin_user" ]; then
                echo "Obsidian users must not share the server admin username" >&2
                return 1
              fi
              doc_id="org.couchdb.user:$user"

              # Create or update the CouchDB user document.
              rev="$(curl -sS -u "$auth" "${base}/_users/$doc_id" 2>/dev/null | jq -r '._rev // empty')"
              doc="$(jq -n --arg n "$user" --arg p "$pass" \
                '{name:$n,password:$p,roles:[],type:"user"}')"
              if [ -n "$rev" ]; then
                curl -fsS -u "$auth" -X PUT "${base}/_users/$doc_id" \
                  -H "If-Match: $rev" -H "Content-Type: application/json" \
                  -d "$doc" >/dev/null || return 1
              else
                curl -fsS -u "$auth" -X PUT "${base}/_users/$doc_id" \
                  -H "Content-Type: application/json" \
                  -d "$doc" >/dev/null || return 1
              fi

              # Create the ordinary account before removing its persisted admin grant.
              status="$(curl -sS -u "$auth" -X DELETE \
                "${base}/_node/_local/_config/admins/$user" -o /dev/null -w '%{http_code}')" || return 1
              case "$status" in
                200|404) ;;
                *) echo "Could not revoke the server-admin grant for $user (HTTP $status)" >&2; return 1 ;;
              esac

              # Create each per-user database and restrict it to the user.
              for db_name in "$@"; do
                full_db="$user-$db_name"
                curl -fsS -u "$auth" -X PUT "${base}/$full_db" >/dev/null 2>&1 || true

                sec="$(jq -n --arg u "$user" \
                  '{admins:{names:[],roles:["_admin"]},members:{names:[$u],roles:[]}}')"
                curl -fsS -u "$auth" -X PUT "${base}/$full_db/_security" \
                  -H "Content-Type: application/json" \
                  -d "$sec" >/dev/null || return 1
              done
            }

            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (userKey: dbs: ''
                provision_user ${secretFor userKey} ${lib.concatStringsSep " " dbs}
              '') vaults
            )}
          '';
      };
    };
}
