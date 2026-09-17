{
  flake.modules.nixos.server = {
    systemd.tmpfiles.rules = [
      "d /var/lib/private 0700 - - -"
      "d /var/cache/private 0700 - - -"
      "d /var/log/private 0700 - - -"
      "d /run/private 0700 - - -"
    ];
  };
}
