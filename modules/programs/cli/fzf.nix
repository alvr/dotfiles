{
  flake.modules.homeManager.fzf = { lib, pkgs, ... }: {
    programs.fzf = {
      enable = true;
      enableFishIntegration = true;

      changeDirWidget.command = "${lib.getExe pkgs.fd} --type d --hidden --follow --exclude .git";
      fileWidget.command = "${lib.getExe pkgs.fd} --type f --hidden --follow --exclude .git";
    };

    programs.fish.interactiveShellInit = lib.mkAfter ''
      if test -f ~/.config/fzf/themes/noctalia.fish
        source ~/.config/fzf/themes/noctalia.fish
      end
    '';
  };
}
