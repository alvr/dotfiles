{
  flake.modules.homeManager.nextcloud-client = {
    services.nextcloud-client = {
      enable = true;
      startInBackground = true;
    };
  };
}
