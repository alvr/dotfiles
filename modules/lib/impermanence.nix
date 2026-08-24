{
  config.flake.lib.mkIfPersistence =
    config: settings:
    if config ? home then
      (if config.home ? persistence then settings else { })
    else
      (if config.environment ? persistence then settings else { });
}
