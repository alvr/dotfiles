{
  flake.modules.homeManager.obs-studio = { pkgs, ... }: {
    programs.obs-studio = {
      enable = true;

      plugins = with pkgs.obs-studio-plugins; [
        advanced-scene-switcher
        input-overlay
        obs-backgroundremoval
        obs-gstreamer
        obs-multi-rtmp
        obs-pipewire-audio-capture
        obs-vaapi
        obs-vkcapture
      ];
    };
  };
}
