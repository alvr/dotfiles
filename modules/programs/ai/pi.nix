{
  flake.modules.homeManager.pi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.pi-coding-agent.enable = true;

      home.file."${config.programs.pi-coding-agent.configDir}/mcp.json" =
        lib.mkIf (config.programs.mcp.enable && config.programs.mcp.servers != { })
          {
            # pi resolves `${VAR}` and `!command`, but not opencode's
            # `{file:…}`, so render the shared config with those refs turned
            # into `!cat <path>` (evaluated at startup, secret stays in the
            # sops file).
            source = pkgs.runCommandLocal "pi-mcp.json" { } ''
              sed -E 's/"\{file:([^}]*)\}"/"!cat \1"/g' \
                ${config.xdg.configFile."mcp/mcp.json".source} > $out
            '';
          };
    };
}
