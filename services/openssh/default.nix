{ config, lib, ... }:
let
  cfg = config.dot.services.openssh;
in
{
  options.dot.services.openssh = {
    enable = lib.mkEnableOption "Enable OpenSSH service";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        AllowUsers = [ "alvr" ];
        ClientAliveCountMax = 2;
        ClientAliveInterval = 300;
        LoginGraceTime = 60;
        MaxAuthTries = 3;
        MaxStartups = "10:30:100";
        PasswordAuthentication = false;
        PermitEmptyPasswords = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
      };
      ports = [ 1311 ];
      openFirewall = true;
    };
  };
}
