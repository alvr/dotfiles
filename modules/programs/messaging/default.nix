{ self, ... }:
{
  flake.modules = {
    nixos.messaging = {
      imports = with self.modules.nixos; [
        telegram
        whatsapp
      ];
    };

    homeManager.messaging = {
      imports = with self.modules.homeManager; [
        equibop
        telegram
      ];
    };
  };
}
