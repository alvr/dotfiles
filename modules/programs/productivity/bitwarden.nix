{
  flake.modules = {
    nixos.bitwarden = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        bitwarden-cli
        bitwarden-desktop
      ];
    };

    homeManager.bitwarden = { config, pkgs, ... }: {
      programs.rbw = {
        enable = true;

        settings = {
          base_url = "https://vault.alvr.dev";
          email = config.dot.host.user.email;
          pinentry = pkgs.pinentry-qt;
          sso_id = "vaultwarden";
        };
      };
    };
  };
}
