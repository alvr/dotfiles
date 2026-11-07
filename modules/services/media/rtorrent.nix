{
  flake.modules.nixos.rtorrent =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      subdomain = "bt";
      port = 9091;
      dhtPort = 34678;
      peerPort = 56789;

      incompleteDir = "/data/media-center/downloads/incomplete";
      completedDir = "/data/media-center/downloads/completed";

      # TODO: remove after https://github.com/NixOS/nixpkgs/pull/583970 in upstream
      baseConfig = ''
        # Instance layout (base paths)
        method.insert = cfg.basedir, private|const|string, (cat,"${config.services.rtorrent.dataDir}/")
        method.insert = cfg.watch,   private|const|string, (cat,(cfg.basedir),"watch/")
        method.insert = cfg.logs,    private|const|string, (cat,(cfg.basedir),"log/")
        method.insert = cfg.logfile, private|const|string, (cat,(cfg.logs),(system.time),".log")
        method.insert = cfg.rpcsock, private|const|string, (cat,"${config.services.rtorrent.rpcSocket}")

        # Create instance directories
        execute.throw = sh, -c, (cat, "mkdir -p ", (cfg.basedir), "/session ", (cfg.watch), " ", (cfg.logs))

        # Listening port for incoming peer traffic (fixed; you can also randomize it)
        network.listen.port.range.set = ${toString config.services.rtorrent.port}-${toString config.services.rtorrent.port}
        network.listen.port.random.set = no

        # Tracker-less torrent and UDP tracker support
        # (conservative settings for 'private' trackers, change for 'public')
        dht.mode.set = disable
        protocol.pex.set = no
        trackers.use_udp.set = no

        # Peer settings
        throttle.max_uploads.set = 100
        throttle.max_uploads.global.set = 250

        throttle.min_peers.normal.set = 20
        throttle.max_peers.normal.set = 60
        throttle.min_peers.seed.set = 30
        throttle.max_peers.seed.set = 80
        trackers.numwant.set = 80

        protocol.encryption.set = allow_incoming,try_outgoing,enable_retry

        # Memory resource usage (increase if you have a large number of items loaded,
        # and/or the available resources to spend)
        pieces.memory.max.set = 1800M
        network.xmlrpc.size_limit.set = 4M

        # Basic operational settings (no need to change these)
        session.path.set = (cat, (cfg.basedir), "session/")
        directory.default.set = "${config.services.rtorrent.downloadDir}"
        log.execute = (cat, (cfg.logs), "execute.log")
        ##log.xmlrpc = (cat, (cfg.logs), "xmlrpc.log")
        execute.nothrow = sh, -c, (cat, "echo >", (session.path), "rtorrent.pid", " ", (system.pid))

        # Other operational settings (check & adapt)
        system.umask.set = 0027
        system.cwd.set = (cfg.basedir)
        network.http.dns_cache_timeout.set = 25
        schedule = monitor_diskspace, 15, 60, ((close_low_diskspace, 1000M))

        # Watch directories (add more as you like, but use unique schedule names)
        #schedule = watch_start, 10, 10, ((load.start, (cat, (cfg.watch), "start/*.torrent")))
        #schedule = watch_load, 11, 10, ((load.normal, (cat, (cfg.watch), "load/*.torrent")))

        # Logging:
        #   Groups = connection_* dht_* peer_* rpc_* storage_* thread_* tracker_* torrent_*
        print = (cat, "Logging to ", (cfg.logfile))
        log.open_file = "log", (cfg.logfile)
        log.add_output = "errors", "log"
        log.add_output = "events", "log"
        ##log.add_output = "tracker_debug", "log"

        # XMLRPC
        scgi_local = (cfg.rpcsock)
        schedule = scgi_group,0,0,"execute.nothrow=chown,\":${config.services.rtorrent.group}\",(cfg.rpcsock)"
        schedule = scgi_permission,0,0,"execute.nothrow=chmod,\"g+w,o=\",(cfg.rpcsock)"
      '';
    in
    {
      services = {
        rtorrent = {
          enable = true;
          dataPermissions = "0700";
          downloadDir = incompleteDir;
          port = peerPort;
          openFirewall = true;

          # TODO: revert this too
          configText = lib.mkForce (
            baseConfig
            + ''
              # Ratelimit to 30MiB/s on down, 10MiB/s on up
              throttle.global_down.max_rate.set_kb = 30720
              throttle.global_up.max_rate.set_kb = 10240

              # Peer settings
              throttle.max_peers.normal.set = 128
              throttle.min_peers.seed.set = 20
              throttle.max_peers.seed.set = 128
              throttle.max_downloads.global.set = 5
              throttle.max_uploads.global.set = 15
              throttle.max_uploads.set = 200
              network.max_open_sockets.set = 512

              # Ports & Trackers
              dht.mode.set = auto
              dht.port.set = ${toString dhtPort}
              protocol.pex.set = yes
              trackers.use_udp.set = yes

              # Add bootstrap nodes for DHT
              schedule = dht_node_1, 15, 0, "dht.add_node=router.utorrent.com:6881"
              schedule = dht_node_2, 15, 0, "dht.add_node=dht.transmissionbt.com:6881"
              schedule = dht_node_3, 15, 0, "dht.add_node=router.bitcomet.com:6881"
              schedule = dht_node_4, 15, 0, "dht.add_node=dht.aelitis.com:6881"

              # Preallocation & permissions
              system.file.allocate.set = 1
              system.umask.set = 0002

              # Directories management
              method.insert = cfg.download_complete, private|const|string, \
                  "${completedDir}/"
              method.insert = d.get_finished_dir, simple, \
                  "cat=$cfg.download_complete=,$d.custom1="
              method.insert = d.data_path, simple, \
                  "if=(d.is_multi_file),(cat,(d.directory),/),(cat,(d.directory),/,(d.name))"
              method.insert = d.move_to_complete, simple, \
                  "d.close=; \
                   execute=${pkgs.coreutils}/bin/mkdir,-p,$argument.1=; \
                   execute=${pkgs.coreutils}/bin/mv,-u,$argument.0=,$argument.1=; \
                   d.directory.set=$argument.1=; \
                   d.start=;d.save_full_session="
              method.set_key = event.download.finished, move_complete, \
                  "d.move_to_complete=$d.data_path=,$d.get_finished_dir="

              # Verify hash on completion
              pieces.hash.on_completion.set = yes
            ''
          );
        };

        flood = {
          enable = true;
          inherit port;
          extraArgs = [
            "--auth=none"
            "--rtsocket=${config.services.rtorrent.rpcSocket}"
            "--allowedpath=${incompleteDir}"
            "--allowedpath=${completedDir}"
          ];
        };

        nginx.virtualHosts."rtorrent-rpc" = {
          listenAddresses = [ "127.0.0.1" ];
          listen = [
            {
              addr = "127.0.0.1";
              port = config.services.rtorrent.port + 1;
            }
          ];
          locations."/RPC2".extraConfig = ''
            include ${config.services.nginx.package}/conf/scgi_params;
            scgi_pass unix:${config.services.rtorrent.rpcSocket};
          '';
        };
      };

      dot.services = {
        nginx.hosts = [
          {
            inherit subdomain port;
            internal = true;

            config.locations."/" = {
              proxyWebsockets = true;
              extraConfig = ''
                proxy_buffering off;
                proxy_cache off;
              '';
            };

            oidc.allowedGroups = [ "bt_users" ];
          }
        ];
      };

      dot.system.persistence.directories = [
        {
          directory = "/var/lib/rtorrent";
          user = "rtorrent";
          group = "rtorrent";
          mode = "u=rwx,g=,o=";
        }
        "/var/lib/private/flood"
      ];

      systemd = {
        services = {
          flood = {
            requires = [ "rtorrent.service" ];
            after = [ "rtorrent.service" ];

            path = [ pkgs.mediainfo ];

            serviceConfig = {
              ReadWritePaths = [
                completedDir
                incompleteDir
                "/var/lib/rtorrent"
              ];
              SupplementaryGroups = [ config.services.rtorrent.group ];
              User = config.services.rtorrent.user;
            };
          };

          nginx.serviceConfig.SupplementaryGroups = [ config.services.rtorrent.group ];
        };

        tmpfiles.rules = [
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
