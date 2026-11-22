{ inputs, ... }:
{
  flake.modules.homeManager.nvchad = { pkgs, ... }: {
    imports = [ inputs.nix4nvchad.homeManagerModules.default ];

    programs.nvchad = {
      enable = true;

      extraPackages = [ pkgs.wakatime-cli ];

      extraPlugins = ''
        return {
          { "wakatime/vim-wakatime" },
        }
      '';
    };
  };
}
