{ inputs, ... }:
{
  flake.modules.nixos.bootvine = {
    imports = [ inputs.bootvine.nixosModules.bootvine ];

    nix.settings = {
      extra-substituters = [ "https://wvhulle.cachix.org" ];
      extra-trusted-public-keys = [ "wvhulle.cachix.org-1:heXx8DZMiRsKUx6l1TxNoF+Nmtmz66QEdsonQzc1ir0=" ];
    };

    services.bootvine.enable = true;
  };
}
