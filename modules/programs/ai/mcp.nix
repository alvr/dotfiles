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
      sops.secrets = {
        "mcp-token/context7" = {
          sopsFile = "${inputs.secrets}/users/${config.dot.host.user.alias}/mcps.yaml";
          mode = "0400";
        };

        "mcp-token/github" = {
          sopsFile = "${inputs.secrets}/users/${config.dot.host.user.alias}/mcps.yaml";
          mode = "0400";
        };
      };

      programs.mcp = {
        enable = true;

        servers = {
          # Documentation
          astro.url = "https://mcp.docs.astro.build/mcp";
          deepwiki.url = "https://mcp.deepwiki.com/mcp";
          nixos.command = lib.getExe pkgs.mcp-nixos;
          context7 = {
            command = lib.getExe pkgs.context7-mcp;
            args = [ "stdio" ];
            env.CONTEXT7_API_KEY.file = config.sops.secrets."mcp-token/context7".path;
          };

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
