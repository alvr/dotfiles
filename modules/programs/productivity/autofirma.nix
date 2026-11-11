{ inputs, ... }:
{
  flake.modules = {
    nixos.autofirma = { pkgs, ... }: {
      services.pcscd.enable = true;

      environment.systemPackages = [
        pkgs.opensc
      ];
    };

    homeManager.autofirma =
      { config, pkgs, ... }:
      {
        imports = [ inputs.omniflake.pinned.autofirma-nix.homeManagerModules.default ];

        programs = {
          autofirma.enable = true;
          configuradorfnmt.enable = true;
        };

        # autofirma-nix only knows how to wire itself into programs.firefox.
        # Zen is managed by the zen-browser-flake module, so apply the same
        # prefs and policies there manually.
        programs.zen-browser = {
          policies = {
            Certificates = {
              ImportEnterpriseRoots = true;
              Install = [ "${config.home.homeDirectory}/.afirma/Autofirma/Autofirma_ROOT.cer" ];
            };

            SecurityDevices = {
              "OpenSC PKCS#11" = "${pkgs.opensc}/lib/opensc-pkcs11.so";
            };
          };

          profiles.default.settings = {
            "network.protocol-handler.app.afirma" = "${config.programs.autofirma.finalPackage}/bin/autofirma";
            "network.protocol-handler.warn-external.afirma" = false;
            "network.protocol-handler.external.afirma" = true;

            "network.protocol-handler.app.fnmtcr" =
              "${config.programs.configuradorfnmt.finalPackage}/bin/configuradorfnmt";
            "network.protocol-handler.warn-external.fnmtcr" = false;
            "network.protocol-handler.external.fnmtcr" = true;
          };
        };
      };
  };
}
