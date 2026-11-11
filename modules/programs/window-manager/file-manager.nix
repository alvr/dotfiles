{
  flake.modules = {
    nixos.file-manager = { pkgs, ... }: {
      environment.systemPackages = with pkgs.kdePackages; [
        ark
        dolphin
        kio
        kio-extras
        kio-fuse
        qt6ct

        pkgs.photoqt
      ];
    };

    homeManager.file-manager = { lib, ... }: {
      xdg.mimeApps.defaultApplications = {
        "image/*" = "org.photoqt.PhotoQt.desktop";
        "inode/directory" = "org.kde.dolphin.desktop";
      }
      // lib.genAttrs [
        "application/gzip"
        "application/vnd.rar"
        "application/x-7z-compressed"
        "application/x-bzip2"
        "application/x-bzip-compressed-tar"
        "application/x-compressed-tar"
        "application/x-rar"
        "application/x-tar"
        "application/x-xz"
        "application/zip"
        "application/zstd"
      ] (_: "org.kde.ark.desktop");
    };
  };
}
