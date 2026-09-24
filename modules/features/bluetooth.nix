{ self, ... }:
{
  flake.modules.nixos.bluetooth = { config, pkgs, ... }: {
    hardware.bluetooth = {
      enable = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          AutoEnable = true;
          ControllerMode = "bredr";
        };
      };
    };

    services.blueman.enable = true;

    dot = self.lib.mkIfSystemPersistence config {
      system.persistence.directories = [ "/var/lib/bluetooth" ];
    };

    systemd.user.services.mpris-proxy = {
      description = "Mpris proxy";
      after = [
        "network.target"
        "sound.target"
      ];
      wantedBy = [ "default.target" ];
      serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };
  };
}
