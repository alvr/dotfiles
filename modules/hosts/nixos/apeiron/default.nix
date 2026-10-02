{ inputs, self, ... }:
{
  flake.nixosConfigurations.apeiron = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.modules.nixos; [
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
      bookorbit
      flaresolverr
      jackett
      jellyfin
      jellyfin-apeiron
      radarr
      rtorrent
      seerr
      sonarr

      # Services - Monitoring
      grafana
      prometheus
      umami
      uptime-kuma

      # Services - Productivity
      actual-budget
      miniflux
      nextcloud
      papra
      readeck

      # Services - Security
      pocket-id
      vaultwarden
    ];
  };
}
