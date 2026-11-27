{
  flake.modules.homeManager.rtk =
    { pkgs, ... }:
    let
      # Bump: `nix-prefetch-url --type sha256 <url> | xargs nix hash convert --hash-algo sha256 --to sri`
      hooksVersion = "1.2.1";

      hooks = {
        pi = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/rtk-ai/rtk/v${hooksVersion}/hooks/pi/rtk.ts";
          hash = "sha256-0VVeCvWHKjDtBAWUIzUL2zgwLyAKlkLFqbzFGclaIlc=";
        };
        opencode = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/rtk-ai/rtk/v${hooksVersion}/hooks/opencode/rtk.ts";
          hash = "sha256-8bGpmEJhboJMMGEsw3xn5LddOPI0asy+ecJAz0vDE2g=";
        };
      };
    in
    {
      home.packages = [ pkgs.rtk ];

      home.file.".pi/agent/extensions/rtk.ts".source = hooks.pi;
      programs.opencode.settings.plugin = [ hooks.opencode ];

      xdg.configFile."rtk/config.toml".text = ''
        [display]
        pro_hint = false
      '';
    };
}
