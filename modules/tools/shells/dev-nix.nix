{
  perSystem = { pkgs, ... }: {
    devshells.dev-nix.devshell = {
      name = "dev-nix";

      packages = with pkgs; [
        deploy-rs
        flake-edit
        git
        just
        nixd
        prek
        sops
        statix
      ];

      startup.prek.text = ''
        prek install -f --hook-type pre-commit
      '';
    };
  };
}
