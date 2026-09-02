{
  config,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.leviathan = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      leviathan
    ];
  };
}
