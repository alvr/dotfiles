{
  flake.modules.homeManager.whatsapp = { pkgs, ... }: {
    home.packages = [ pkgs.zapfast ];
  };
}
