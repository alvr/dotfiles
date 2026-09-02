{
  perSystem = { pkgs, ... }: {
    devenv.shells.dev-nix = {
      languages.nix.enable = true;

      packages = with pkgs; [
        git
        just
        prek
        rclone
        sops
        statix
      ];

      enterShell = ''
        prek install -f --hook-type pre-commit
      '';
    };
  };
}
