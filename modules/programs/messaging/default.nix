{ self, ... }:
{
  flake.modules.homeManager.messaging = {
    imports = with self.modules.homeManager; [
      equibop
      telegram
      whatsapp
    ];
  };
}
