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

            admin_file="$(cat ${config.sops.secrets."couchdb/admin".path})"
            IFS=' = ' read -r admin_user admin_pass <<< "$(grep -v '^\[' <<< "$admin_file")"
            auth="$admin_user:$admin_pass"

            # Wait until CouchDB is ready to accept authenticated requests.
            for _ in $(seq 1 60); do
              if curl -fsS -u "$auth" "${base}/_up" >/dev/null 2>&1; then
                break
              fi
              sleep 1
            done

            # Discover the local node name for the config API.
            node_name="$(curl -fsS -u "$auth" "${base}/_membership" | jq -r '.all_nodes[0]')"

            # Ensure the system databases exist (idempotent).
            for db in _users _replicator _global_changes; do
              curl -fsS -u "$auth" -X PUT "${base}/$db" >/dev/null 2>&1 || true
            done

            provision_user() {
              { read -r user; read -r pass; } < "$1"
              shift
              doc_id="org.couchdb.user:$user"

              # Create or update the CouchDB user document.
              rev="$(curl -sS -u "$auth" "${base}/_users/$doc_id" 2>/dev/null | jq -r '._rev // empty')"
              doc="$(jq -n --arg n "$user" --arg p "$pass" \
                '{name:$n,password:$p,roles:[],type:"user"}')"
              if [ -n "$rev" ]; then
                curl -fsS -u "$auth" -X PUT "${base}/_users/$doc_id" \
                  -H "If-Match: $rev" -H "Content-Type: application/json" \
                  -d "$doc" >/dev/null || true
              else
                curl -fsS -u "$auth" -X PUT "${base}/_users/$doc_id" \
                  -H "Content-Type: application/json" \
                  -d "$doc" >/dev/null || true
              fi

              # Register the user as a server admin (required by the plugin for database deletion).
              curl -fsS -u "$auth" -X PUT "${base}/_node/$node_name/_config/admins/$user" \
                -H "Content-Type: application/json" \
                -d "\"$pass\"" >/dev/null || true

              # Create each per-user database and restrict it to the user.
              for db_name in "$@"; do
                full_db="$user-$db_name"
                curl -fsS -u "$auth" -X PUT "${base}/$full_db" >/dev/null 2>&1 || true

                sec="$(jq -n --arg u "$user" \
                  '{admins:{names:[$u],roles:["_admin"]},members:{names:[$u],roles:[]}}')"
                curl -fsS -u "$auth" -X PUT "${base}/$full_db/_security" \
                  -H "Content-Type: application/json" \
                  -d "$sec" >/dev/null || true
              done
            }

            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (userKey: dbs: ''
                provision_user ${secretFor userKey} ${lib.concatStringsSep " " dbs}
              '') vaults
            )}

            # Install the Photon template design document (skip if already installed).
            if ! curl -fsS -u "$auth" "${base}/photon/_design/photon" >/dev/null 2>&1; then
              curl -fsS -u "$auth" -X PUT "${base}/photon" >/dev/null 2>&1 || true
              curl -fsS https://raw.githubusercontent.com/ermouth/couch-photon/master/photon.json | \
                curl -fsS -u "$auth" -X PUT "${base}/photon/_design/photon" \
                  -H "Content-Type: application/json" -d @- >/dev/null 2>&1 || true
              curl -fsS -u "$auth" -X PUT "${base}/photon/_security" \
                -H "Content-Type: application/json" -d '{}' >/dev/null 2>&1 || true
              curl -fsS -u "$auth" -X PUT "${base}/_node/$node_name/_config/csp/attachments_enable" \
                -H "Content-Type: application/json" -d '"false"' >/dev/null 2>&1 || true
              curl -fsS -u "$auth" -X PUT "${base}/_node/$node_name/_config/chttpd_auth/same_site" \
                -H "Content-Type: application/json" -d '"lax"' >/dev/null 2>&1 || true
            fi
          '';
      };
    };
}
