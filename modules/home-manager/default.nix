{ inputs, ... }:
{
  home-manager = {
    backupFileExtension = ".bak";
    useGlobalPkgs = true;
    useUserPackages = true;

    sharedModules = [
      inputs.impermanence.homeManagerModules.impermanence
      inputs.sops-nix.homeManagerModules.sops

      { home.enableNixpkgsReleaseCheck = false; }

      ./git.nix
      ./persistence.nix
      ./sops.nix
    ];
  };
}
