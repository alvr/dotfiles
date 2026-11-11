{ inputs, ... }:
{
  flake.modules.nixos.helium-browser = { config, ... }: {
    imports = [ inputs.omniflake.flakes.nix-flake-helium-browser.nixosModules.default ];

    programs.helium = {
      enable = true;

      policies = {
        RestoreOnStartup = 1;
        ApplicationLocaleValue = "es";

        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "DuckDuckGo";
        DefaultSearchProviderKeyword = "duckduckgo.com";
        DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
        DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
        DefaultSearchProviderIconURL = "https://duckduckgo.com/favicon.ico";

        ExtensionInstallForcelist = [
          "lppmekppnliemjclknbagdhoocikieoi;https://clients2.google.com/service/update2/crx" # 7TV
          "dnhpnfgdlenaccegplpojghhmaamnnfp;https://clients2.google.com/service/update2/crx" # Augmented Steam
          "nngceckbapebfimnlniiiahkandclblb;https://clients2.google.com/service/update2/crx" # Bitwarden
          "eimadpbcbfnmbkopoojfekhnkhdbieeh;https://clients2.google.com/service/update2/crx" # Dark Reader
          "fnaicdffflnofjppbagibeoednhnbjhg;https://clients2.google.com/service/update2/crx" # floccus
          "neebplgakaahbhdphmkckjjcegoiijjo;https://clients2.google.com/service/update2/crx" # Keepa
          "edibdbjcniadpccecjdfdjjppcpchdlm;https://clients2.google.com/service/update2/crx" # I still don't care about cookies
          "cjpalhdlnbpafiamejdnhcphjbkeiagm;https://clients2.google.com/service/update2/crx" # uBlock Origin
          "jinjaccalgkegednnccohejagnlnfdag;https://clients2.google.com/service/update2/crx" # Violentmonkey
          "hhinaapppaileiechjoiifaancjggfjm;https://clients2.google.com/service/update2/crx" # Web Scrobbler
        ];
      };
    };

    systemd.tmpfiles.settings."10-noctalia-chromium"."/etc/chromium/policies/managed/noctalia-color.json".f =
      {
        user = config.dot.host.user.alias;
        group = "users";
        mode = "0644";
        argument = "{}";
      };
  };

  flake.modules.homeManager.helium-browser = { pkgs, ... }: {
    xdg.configFile."net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm".text =
      builtins.toJSON
        {
          Path = "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm";
        };
  };
}
