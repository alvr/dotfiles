{
  flake.modules.nixos.steam =
    { pkgs, ... }:
    {
      programs = {
        gamemode.enable = true;
        gamescope.capSysNice = true;

        steam = {
          enable = true;
          extest.enable = true;
          gamescopeSession.enable = true;
          protontricks.enable = true;
          remotePlay.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;

          extraPackages = with pkgs; [
            gamemode
            gamescope
            mangohud
          ];
          extraCompatPackages = with pkgs; [
            proton-ge-custom
            proton-cachyos_x86_64_v3
          ];
        };
      };
    };
}
