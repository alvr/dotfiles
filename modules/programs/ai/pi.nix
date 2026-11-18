{
  flake.modules.homeManager.pi = { config, lib, ... }: {
    programs.pi-coding-agent.enable = true;

    home.file."${config.programs.pi-coding-agent.configDir}/mcp.json" =
      lib.mkIf (config.programs.mcp.enable && config.programs.mcp.servers != { })
        {
          source = config.xdg.configFile."mcp/mcp.json".source;
        };
  };
}
