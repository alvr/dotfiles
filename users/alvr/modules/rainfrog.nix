{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      rainfrog
    ];

    file.".config/rainfrog/rainfrog_config.toml".text = ''
      [db]
      forgejo = { connection_string = "postgresql://forgejo@localhost:5432/forgejo?host=/run/postgresql", driver = "postgres" }
      linkwarden = { connection_string = "postgresql://linkwarden@localhost:5432/linkwarden?host=/run/postgresql", driver = "postgres" }
      miniflux = { connection_string = "postgresql://miniflux@localhost:5432/miniflux?host=/run/postgresql", driver = "postgres" }
      paperless = { connection_string = "postgresql://paperless@localhost:5432/paperless?host=/run/postgresql", driver = "postgres" }
      pocket-id = { connection_string = "postgresql://pocket-id@localhost:5432/pocket-id?host=/run/postgresql", driver = "postgres" }
      vaultwarden = { connection_string = "postgresql://vaultwarden@localhost:5432/vaultwarden?host=/run/postgresql", driver = "postgres" }
    '';
  };
}
