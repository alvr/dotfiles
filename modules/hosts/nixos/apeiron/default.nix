{
  config,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.apeiron = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      # System
      apeiron

      # Services - Automation
      home-assistant

      # Services - Core
      cloudflared
      duckdns
      nginx
      restic
      tailscale

      # Services - Databases
      couchdb
      mariadb
      postgresql

      # Services - Development
      forgejo
      wakapi

      # Services - Media
      bazarr
      flaresolverr
      grimmory
      jackett
      jellyfin
      radarr
      seerr
      sonarr
      transmission

      # Services - Monitoring
      grafana
      prometheus
      umami
      uptime-kuma

      # Services - Productivity
      actual-budget
      miniflux
      nextcloud
      paperless
      readeck

      # Services - Security
      pocket-id
      vaultwarden
    ];
  };
}
