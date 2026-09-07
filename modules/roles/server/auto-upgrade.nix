{
  flake.modules.nixos.server = {
    system.autoUpgrade = {
      enable = true;
      allowReboot = true;
      dates = "03:00";
      flake = "git+https://codeberg.org/alvr/dotfiles.git";
      flags = [ "--commit-lock-file" ];
      rebootWindow.lower = "03:00";
      rebootWindow.upper = "05:00";
    };
  };
}
