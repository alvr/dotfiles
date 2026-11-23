{ inputs, ... }:
let
  # Auto-tracks the Gecko version of the pinned Zen release so the langpack
  # policy always points at a release that exists on releases.mozilla.org.
  zenFirefoxVersion =
    (builtins.fromJSON (builtins.readFile "${inputs.zen-browser}/sources.json"))
    .variants.beta.x86_64-linux.firefoxVersion;

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
    "es-ES@dictionaries.addons.mozilla.org" = "es-ES@dictionaries.addons.mozilla.org";
  };
in
{
  flake.modules.homeManager.zen-browser = {
    imports = [ inputs.zen-browser.homeModules.default ];

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;

      release = zenFirefoxVersion;
      languagePacks = [ "es-ES" ];

      policies = {
        # Accounts, sync, passwords
        DisableFirefoxAccounts = true;
        DisableAccounts = true;
        PasswordManagerEnabled = false;
        OfferToSaveLogins = false;
        DisableTelemetry = true;

        ExtensionSettings = builtins.mapAttrs (_: slug: {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
        }) extensions;
      };

      profiles.default = {
        isDefault = true;

        presets.arkenfox.enable = true;
        presets.betterfox.enable = true;

        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "devtools.chrome.enabled" = true;
          "intl.locale.requested" = "es-ES";
          "intl.accept_languages" = "es-ES, es, en-US, en";

          # Vertical tabs with an auto-hiding sidebar (Zen compact mode).
          "zen.view.compact.enable-at-startup" = true;
          "zen.view.compact.show-sidebar-and-toolbar-on-hover" = true;

          # No gap or rounded border between the webpage and the window.
          "zen.theme.content-element-separation" = 0;
          "zen.theme.border-radius" = 0;

          # Restore the previous session's tabs on startup. Explicitly overrides
          # the arkenfox preset, which sets this to 0 (blank page).
          "browser.startup.page" = 3;
          "browser.sessionstore.resume_from_crash" = true;

          # Spellcheck in Spanish and English (dictionary installed via policy).
          "spellchecker.dictionary" = "es-ES,en-US";
          "layout.spellcheckDefault" = 2;

          # Never offer translations for Spanish or English pages.
          "browser.translations.neverTranslateLanguages" = "es,en";
          "browser.translations.automaticallyPopup" = false;

          # Accounts/passwords (also enforced by policy above).
          "identity.fxaccounts.enabled" = false;
          "signon.rememberSignons" = false;
        };

        search = {
          force = true;
          default = "ddg";
        };
      };
    };
  };
}
