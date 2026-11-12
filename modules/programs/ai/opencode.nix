{
  flake.modules = {
    nixos.opencode = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        opencode-desktop
      ];
    };

    homeManager.opencode = {
      programs.opencode = {
        enable = true;
        settings = {
          "$schema" = "https://opencode.ai/config.json";
          mcp = {
            Astro = {
              enabled = true;
              type = "remote";
              url = "https://mcp.docs.astro.build/mcp";
            };
            NixOS = {
              enabled = true;
              type = "local";
              command = [
                "nix"
                "run"
                "github:utensils/mcp-nixos"
                "--"
              ];
            };
          };
        };
      };
    };
  };
}
