{ inputs, ... }:
{
  flake.modules.homeManager.nvchad = {
    imports = [ inputs.nix4nvchad.homeManagerModules.default ];

    catppuccin.nvim.enable = true;

    programs.nvchad.enable = true;
  };
}
