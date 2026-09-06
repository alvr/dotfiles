{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    devenv.shells.dev-nix = {
      languages.nix.enable = true;

      packages = with pkgs; [
        git
        just
        prek
        sops
        statix
        inputs.deploy-rs.packages.${system}.default
      ];

      enterShell = ''
        prek install -f --hook-type pre-commit
      '';
    };
  };
}
