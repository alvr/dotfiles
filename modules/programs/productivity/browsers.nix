{
  flake.modules.nixos.browsers = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      brave-origin
      nur.repos.novel2430.zen-browser-bin
      nur.repos.Ev357.helium
    ];
  };
}
