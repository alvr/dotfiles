{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      rainfrog
    ];

    file.".config/rainfrog/rainfrog_config.toml".text = ''
      [db]
      forgejo = { connection_string = "postgresql://forgejo@forgejo?host=/run/postgresql", driver = "postgres" }
      linkwarden = { connection_string = "postgresql://linkwarden@linkwarden?host=/run/postgresql", driver = "postgres" }
      miniflux = { connection_string = "postgresql://miniflux@miniflux?host=/run/postgresql", driver = "postgres" }
      paperless = { connection_string = "postgresql://paperless@paperless?host=/run/postgresql", driver = "postgres" }
      pocket-id = { connection_string = "postgresql://pocket-id@pocket-id?host=/run/postgresql", driver = "postgres" }
      vaultwarden = { connection_string = "postgresql://vaultwarden@vaultwarden?host=/run/postgresql", driver = "postgres" }
      wakapi = { connection_string = "postgresql://wakapi@wakapi?host=/run/postgresql", driver = "postgres" }
    '';
  };
}
