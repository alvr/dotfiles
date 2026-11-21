{ inputs, ... }:
{
  flake.modules.homeManager.ai-mcp =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      sops.secrets."mcp-token/github" = {
        sopsFile = "${inputs.secrets}/users/${config.dot.host.user.alias}/mcps.yaml";
        mode = "0400";
      };

      programs.mcp = {
        enable = true;

        servers = {
          # Documentation
          astro.url = "https://mcp.docs.astro.build/mcp";
          context7.url = "https://mcp.context7.com/mcp/oauth";
          nixos.command = lib.getExe pkgs.mcp-nixos;

          # Repositories
          git.command = lib.getExe pkgs.mcp-server-git;
          github = {
            command = lib.getExe pkgs.github-mcp-server;
            args = [ "stdio" ];
            env.GITHUB_PERSONAL_ACCESS_TOKEN.file = config.sops.secrets."mcp-token/github".path;
          };

          # Local files
          filesystem = {
            command = lib.getExe pkgs.mcp-server-filesystem;
            args = [ config.xdg.userDirs.projects ];
          };

          # Web
          fetch.command = lib.getExe pkgs.mcp-server-fetch;
        };
      };
    };
}
