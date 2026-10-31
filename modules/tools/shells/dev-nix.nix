{
  perSystem = { pkgs, ... }: {
    devenv.shells.dev-nix = {
      languages.nix.enable = true;

      packages = with pkgs; [
        deploy-rs
        flake-edit
        git
        just
        prek
        sops
        statix
      ];

      enterShell = ''
        prek install -f --hook-type pre-commit
      '';
    };
  };
}
