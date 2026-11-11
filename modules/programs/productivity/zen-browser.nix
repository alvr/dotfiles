{ inputs, ... }:
let
  extensions = {
    "uBlock0@raymondhill.net" = "ublock-origin";
    "addon@darkreader.org" = "darkreader";
    "amptra@keepa.com" = "keepa";
    "floccus@handmadeideas.org" = "floccus";
    "seventv-next@7tv.app" = "7tv-new";
    "idcac-pub@guus.ninja" = "istilldontcareaboutcookies";
    "{1be309c5-3e4f-4b99-927d-bb500eb4fa88}" = "augmented-steam";
    "{799c0914-748b-41df-a25c-22d008f9e83f}" = "web-scrobbler";
    "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "bitwarden-password-manager";
    "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = "violentmonkey";
  };
in
{
  flake.modules.homeManager.zen-browser = {
    imports = [ inputs.omniflake.flakes.zen-browser-flake.homeModules.default ];

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;

      policies.ExtensionSettings = builtins.mapAttrs (_: slug: {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
      }) extensions;

      profiles.default = {
        isDefault = true;

        presets.arkenfox.enable = true;
        presets.betterfox.enable = true;

        search = {
          force = true;
          default = "ddg";
        };
      };
    };
  };
}
