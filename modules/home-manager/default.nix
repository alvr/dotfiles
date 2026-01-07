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
      inputs.sops-nix.homeManagerModules.sops

      { home.enableNixpkgsReleaseCheck = false; }
    ]
    ++ lib.dot.import ./.;
  };
}
