{ inputs, ... }:
{
  flake.modules = {
    nixos.wakatime = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.wakatime-cli ];
    };

    homeManager.wakatime = { config, ... }: {
      sops.secrets."wakatime/api-key" = {
        sopsFile = "${inputs.secrets}/users/${config.dot.host.user.alias}/wakatime.yaml";
        mode = "0400";
      };

      sops.templates."wakatime.cfg" = {
        path = "${config.home.homeDirectory}/.wakatime.cfg";

        content = ''
          [settings]
          api_key = ${config.sops.placeholder."wakatime/api-key"}
          api_url = https://waka.alvr.dev/api
        '';
      };
    };
  };
}
