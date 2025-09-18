{ ... }:
{
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
}
