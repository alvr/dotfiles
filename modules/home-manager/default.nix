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
      inputs.nixvim.homeModules.nixvim
      inputs.sops-nix.homeManagerModules.sops

      { home.enableNixpkgsReleaseCheck = false; }
    ]
    ++ lib.dot.import ./.;
  };
}
