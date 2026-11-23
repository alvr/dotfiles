{
  flake.modules.nixos.brave-browser = { pkgs, config, ... }: {
    programs.brave = {
      enable = true;
      package = pkgs.brave-origin;

      # Only requirements expressible as Chromium/Brave enterprise policies go
      policies = {
        BrowserSignin = 0;
        SigninAllowed = false;
        PasswordManagerEnabled = false;
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        SyncDisabled = true;
        MetricsReportingEnabled = false;

        SpellcheckEnabled = true;
        SpellcheckLanguage = [
          "en-US"
          "es-ES"
        ];

        RestoreOnStartup = 1;

        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "DuckDuckGo";
        DefaultSearchProviderKeyword = "duckduckgo.com";
        DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
        DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
        DefaultSearchProviderIconURL = "https://duckduckgo.com/favicon.ico";

        # Brave debloat (the Origin experience, enforceable)
        BraveRewardsDisabled = true;
        BraveWalletDisabled = true;
        BraveAIChatEnabled = false;
        BraveVPNDisabled = true;
        BraveNewsDisabled = true;
        BraveP3AEnabled = false;
        BraveStatsPingEnabled = false;
        BraveWebDiscoveryEnabled = false;
      };
    };

    # Noctalia's brave-origin template expects this file to exist with user
    # ownership so it can inject the generated palette at runtime.
    systemd.tmpfiles.settings."10-noctalia-brave"."/etc/brave/policies/managed/noctalia-color.json".f =
      {
        user = config.dot.host.user.alias;
        group = "users";
        mode = "0644";
        argument = "{}";
      };
  };

  flake.modules.homeManager.brave-browser = {
    programs.brave-origin = {
      enable = true;

      # The browser is installed by the NixOS module (stock cached package);
      # don't install a second copy from Home Manager's nixpkgs.
      package = null;

      # Plain IDs use the Chrome Web Store update URL by default. Home Manager
      # writes these to the user's External Extensions directory.
      extensions = [
        "lppmekppnliemjclknbagdhoocikieoi" # 7TV
        "dnhpnfgdlenaccegplpojghhmaamnnfp" # Augmented Steam
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
        "fnaicdffflnofjppbagibeoednhnbjhg" # floccus
        "neebplgakaahbhdphmkckjjcegoiijjo" # Keepa
        "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "jinjaccalgkegednnccohejagnlnfdag" # Violentmonkey
        "hhinaapppaileiechjoiifaancjggfjm" # Web Scrobbler
      ];
    };
  };
}
