{
  flake.modules.nixos.audio =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        alsa-utils
        pavucontrol
        pipewire
        pipewire.jack
        playerctl
        pulseaudioFull
        qpwgraph
      ];

      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        jack.enable = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };
    };
}
