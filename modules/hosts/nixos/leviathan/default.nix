{ inputs, self, ... }:
{
  flake.nixosConfigurations.leviathan = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.modules.nixos; [
      leviathan
    ];
  };
}
