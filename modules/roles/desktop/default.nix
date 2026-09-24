{ self, ... }:
{
  flake.modules.nixos.desktop = { config, ... }: {
    imports = with self.modules.nixos; [
      base
      audio
      bluetooth
      fonts
      nextdns
      printing
      productivity
      sops
    ];

    users.users.${config.dot.host.user.alias}.extraGroups = [
      "audio"
      "camera"
      "lp"
      "scanner"
      "video"
    ];
  };
}
