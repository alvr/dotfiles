{
  consts,
  inputs,
  lib,
  ...
}:
{
  home-manager = {
    backupFileExtension = ".bak";
    extraSpecialArgs = { inherit consts; };
    useGlobalPkgs = true;
    useUserPackages = true;

    sharedModules = [
      inputs.impermanence.homeManagerModules.impermanence
      inputs.sops-nix.homeManagerModules.sops

      { home.enableNixpkgsReleaseCheck = false; }
    ]
    ++ lib.dot.import ./.;
  };
}
