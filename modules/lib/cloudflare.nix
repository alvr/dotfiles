{
  flake.modules.nixos.base =
    { lib, ... }:
    let
      fileToList = x: lib.filter (s: s != "") (lib.strings.splitString "\n" (builtins.readFile x));
    in
    {
      options.dot.lib.cloudflare = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        internal = true;
        readOnly = true;
        description = "Cloudflare IP ranges, fetched once and shared by nginx and fail2ban.";
      };

      config.dot.lib.cloudflare = {
        ipv4 = fileToList (
          builtins.fetchurl {
            url = "https://www.cloudflare.com/ips-v4";
            sha256 = "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
          }
        );
        ipv6 = fileToList (
          builtins.fetchurl {
            url = "https://www.cloudflare.com/ips-v6";
            sha256 = "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
          }
        );
      };
    };
}
