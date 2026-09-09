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
    in
    {
      services = {
        rtorrent = {
          enable = true;
          dataPermissions = "0700";
          downloadDir = incompleteDir;
          port = peerPort;
          openFirewall = true;

          configText = lib.mkAfter ''
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
          '';
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

          rtorrent = {
            requires = [ "nginx.service" ];
            after = [ "nginx.service" ];
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
