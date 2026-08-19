{
  flake.modules.nixos.printing =
    { pkgs, ... }:
    {
      hardware.printers.ensurePrinters = [
        {
          name = "Epson_XP-4200";
          description = "Epson XP-4200";
          deviceUri = "ipps://EPSON24CB36.local:631/ipp/print";
          model = "everywhere";
          ppdOptions = {
            PageSize = "A4";
          };
        }
      ];

      hardware.sane = {
        enable = true;
        extraBackends = [ pkgs.sane-airscan ];
      };

      services.printing = {
        enable = true;
        stateless = true;
        drivers = with pkgs; [
          epson-escpr2
          epsonscan2
        ];
      };

      services.avahi = {
        enable = true;
        nssmdns4 = true;
      };
    };
}
