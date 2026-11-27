{
  flake.modules.nixos.steam = { pkgs, ... }: {
    # Steam's bin_steam.sh expects ~/.steam/steam to be a symlink to the data
    # directory. If it is ever created as a real directory, `ln -fns` nests
    # the link inside it and Steam aborts with:
    #   "Couldn't set up Steam data - please contact technical support"
    # `L+` replaces whatever is there (directory included) on every login,
    # before the graphical session starts. `%D` is the user's
    # ${XDG_DATA_HOME:-~/.local/share}, the same lookup Steam does at runtime.
    systemd.user.tmpfiles.rules = [
      "L+ %h/.steam/steam - - - - %D/Steam"
    ];

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
          proton-ge-bin_edge
          proton-cachyos-bin_x86_64_v3
        ];
      };
    };
  };
}
