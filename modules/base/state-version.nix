{
  flake.modules.nixos.base = { config, ... }: {
    system.stateVersion = config.dot.host.state.version;
  };

  flake.modules.darwin.base = { config, ... }: {
    system.stateVersion = config.dot.host.state.darwin;
  };
}
