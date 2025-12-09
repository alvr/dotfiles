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
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
      ports = [ 1311 ];
      openFirewall = true;
      extraConfig = ''
        MaxAuthTries 15
      '';
    };
  };
}
