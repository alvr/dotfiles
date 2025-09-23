{ ... }:
{
  imports = [
    ../../../modules/home-manager/git.nix
  ];

  home-modules.git = {
    username = "Álvaro Salcedo García";
    email = "alvaro@alvr.dev";
  };
}
