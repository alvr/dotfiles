{
  flake.modules.homeManager.ssh = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings.apeiron = {
        HostName = "192.168.1.200";
        Port = 1311;
        User = "alvr";
        IdentityAgent = "~/.bitwarden-ssh-agent.sock";
      };
    };
  };
}
