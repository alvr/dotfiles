{ self, ... }:
{
  flake.modules.nixos.podman = { config, ... }: {
    virtualisation = {
      oci-containers.backend = "podman";

      podman = {
        enable = true;
        autoPrune.enable = true;
        defaultNetwork.settings.dns_enabled = true;
        dockerCompat = true;
      };
    };

    dot = self.lib.mkIfSystemPersistence config {
      system.persistence.directories = [ "/var/lib/containers" ];
    };
  };
}
