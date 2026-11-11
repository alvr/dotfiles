{
  flake.modules.nixos.openssh = { config, ... }: {
    services.openssh = {
      enable = true;
      settings = {
        AllowUsers = [
          config.dot.host.user.alias
          "root"
        ];
        ClientAliveCountMax = 2;
        ClientAliveInterval = 300;
        LoginGraceTime = 60;
        MaxAuthTries = 5;
        MaxStartups = "10:30:100";
        PasswordAuthentication = false;
        PermitEmptyPasswords = false;
        PermitRootLogin = "prohibit-password";
        X11Forwarding = false;
      };
      ports = [ config.dot.host.network.ssh.port ];
      openFirewall = true;
    };

    users.users.root.openssh.authorizedKeys.keys = config.dot.host.user.sshKeys;

    programs.ssh.extraConfig = ''
      Host *
        SetEnv TERM=xterm-256color
    '';
  };
}
