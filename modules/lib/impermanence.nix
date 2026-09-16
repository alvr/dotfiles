{
  config.flake.lib = {
    mkIfHmPersistence = config: settings: if config.home ? persistence then settings else { };
    mkIfSystemPersistence =
      config: settings: if config.environment ? persistence then settings else { };
  };
}
