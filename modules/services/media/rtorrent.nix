{
  flake.modules.nixos.rtorrent =
    { config, pkgs, ... }:
    let
      subdomain = "bt";
      port = 9091;

      incompleteDir = "/data/media-center/downloads/incomplete";
      completedDir = "/data/media-center/downloads/completed";

      ipfilterFile = "/var/lib/rtorrent/blocklist.txt";

      pythonEnv = pkgs.python3.withPackages (ps: [ ps.netaddr ]);
      blocklistScript = pkgs.writeText "update-rtorrent-blocklist.py" ''
        #!/usr/bin/env python3
        import gzip, urllib.request, netaddr

        data = urllib.request.urlopen("https://github.com/Naunter/BT_BlockLists/raw/master/bt_blocklists.gz").read()
        text = gzip.decompress(data).decode("utf-8", errors="ignore")

        cidrs = set()
        for line in text.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            try:
                _, iprange = line.rsplit(":", 1)
                start, end = (p.strip() for p in iprange.split("-"))
                for cidr in netaddr.iprange_to_cidrs(start, end):
                    cidrs.add(str(cidr))
            except Exception:
                continue

        with open("${ipfilterFile}", "w") as f:
            f.write("\n".join(sorted(cidrs)) + "\n")
      '';
    in
    {
      services.rtorrent = {
        enable = true;
        downloadDir = incompleteDir;

        configText = ''
          # --- Speed limits ---
          throttle.global_down.max_rate.set_kb = 10000
          throttle.global_up.max_rate.set_kb = 5000         

          # --- Peers / uploads ---
          throttle.max_peers.normal.set = 128
          throttle.min_peers.normal.set = 20
          throttle.min_peers.seed.set = 20
          throttle.max_peers.seed.set = 128
          throttle.max_downloads.global.set = 5
          throttle.max_uploads.global.set = 15
          throttle.max_uploads.set = 200
          network.max_open_sockets.set = 512

          # --- Ports & Trackers ---
          dht.mode.set = auto
          network.port_range.set = 55660-60660
          network.port_random.set = yes
          protocol.pex.set = yes
          trackers.use_udp.set = yes

          # --- Preallocation & permissions ---
          system.file.allocate.set = 1
          system.umask.set = 0002

          # --- SCGI socket for Flood RPC ---
          encoding.add = UTF-8

          # --- Directories management ---
          directory.default.set = "${incompleteDir}/"
          method.insert = cfg.download_complete, private|const|string, \
              "${completedDir}/"
          method.insert = d.get_finished_dir, simple, \
              "cat=$cfg.download_complete=,$d.custom1="
          method.insert = d.data_path, simple, \
              "if=(d.is_multi_file),(cat,(d.directory),/),(cat,(d.directory),/,(d.name))"
          method.insert = d.move_to_complete, simple, \
              "execute=${pkgs.coreutils}/bin/mkdir,-p,$argument.1=; \
               execute=${pkgs.coreutils}/bin/mv,-u,$argument.0=,$argument.1=; \
               d.directory.set=$argument.1=; \
               d.save_full_session="
          method.set_key = event.download.finished, move_complete, \
              "d.move_to_complete=$d.data_path=,$d.get_finished_dir="

          # --- Blocklist ---
          ipv4_filter.load = ${ipfilterFile}, unwanted
        '';
      };

      services.flood = {
        enable = true;
        inherit port;
        extraArgs = [
          "--auth=none"
          "--rtsocket=${config.services.rtorrent.rpcSocket}"
          "--allowedpath=/data/media-center/downloads"
        ];
      };

      dot.services = {
        nginx.hosts = [
          {
            inherit subdomain port;
            internal = true;
            config.locations."/".proxyWebsockets = true;

            oidc.allowedGroups = [ "transmission_users" ];
          }
        ];
      };

      systemd = {
        services = {
          flood = {
            requires = [
              "nginx.service"
              "pocket-id.service"
              "rtorrent.service"
            ];
            after = [
              "nginx.service"
              "pocket-id.service"
              "rtorrent.service"
            ];

            serviceConfig.SupplementaryGroups = [ config.services.rtorrent.group ];
          };

          rtorrent-blocklist-update = {
            description = "Update rtorrent IP blocklist from Naunter/BT_BlockLists";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pythonEnv}/bin/python3 ${blocklistScript}";
              User = config.services.rtorrent.user;
              Group = config.services.rtorrent.group;
            };
          };
        };

        timers.rtorrent-blocklist-update = {
          description = "Daily rtorrent blocklist refresh";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "Fri *-*-* 00:00:00";
            Persistent = true;
          };
        };

        tmpfiles.rules = [
          "d /var/lib/rtorrent 0700 rtorrent media -"

          "d /data/media-center/downloads 2770 rtorrent media -"

          "d ${completedDir} 2770 rtorrent media -"
          "Z ${completedDir} 2770 rtorrent media -"

          "d ${incompleteDir} 2770 rtorrent media -"
          "Z ${incompleteDir} 2770 rtorrent media -"
        ];
      };

      users.groups.media = { };
      users.users.rtorrent.extraGroups = [ "media" ];
    };
}
