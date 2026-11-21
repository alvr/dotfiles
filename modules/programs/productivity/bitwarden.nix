{
  flake.modules = {
    nixos.bitwarden = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        bitwarden-cli
        bitwarden-desktop
      ];
    };

    homeManager.bitwarden = { config, pkgs, ... }: {
      sshAuthSock.initialization.fish = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
      home.sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";

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
