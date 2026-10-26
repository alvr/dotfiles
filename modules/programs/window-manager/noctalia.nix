{ inputs, ... }:
{
  flake.modules.nixos.noctalia = {
    imports = [ inputs.noctalia.nixosModules.default ];

    nix.settings = {
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };

    programs.noctalia = {
      enable = true;
      recommendedServices.enable = true;
    };

    security.polkit.enable = true;
  };
}
