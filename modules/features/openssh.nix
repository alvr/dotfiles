{
  flake.modules.nixos.openssh =
    { config, ... }:
    {
      services.openssh = {
        enable = true;
        settings = {
          AllowUsers = [ config.dot.host.user.alias ];
          ClientAliveCountMax = 2;
          ClientAliveInterval = 300;
          LoginGraceTime = 60;
          MaxAuthTries = 5;
          MaxStartups = "10:30:100";
          PasswordAuthentication = false;
          PermitEmptyPasswords = false;
          PermitRootLogin = "no";
          X11Forwarding = false;
        };
        ports = [ config.dot.host.network.ssh.port ];
        openFirewall = true;
      };

      programs.ssh.extraConfig = ''
        Host *
          SetEnv TERM=xterm-256color
      '';
    };
}
