{
  flake.modules.nixos.server = {
    systemd.tmpfiles.rules = [
      "d /var/lib/private 0700 root root -"
      "d /var/cache/private 0700 root root -"
      "d /var/log/private 0700 root root -"
      "d /run/private 0700 root root -"
    ];
  };
}
