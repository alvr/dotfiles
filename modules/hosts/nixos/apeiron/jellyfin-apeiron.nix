{
  flake.modules.nixos.jellyfin-apeiron = {
    # apeiron: Ryzen 7 8845HS w/ Radeon 780M (RDNA3/VCN4) via amdgpu.
    services.jellyfin = {
      hardwareAcceleration = {
        enable = true;
        type = "vaapi";
        device = "/dev/dri/renderD128";
      };

      # Already deployed, so force config or encoding.xml is ignored.
      forceEncodingConfig = true;

      transcoding = {
        enableHardwareEncoding = true;
        enableToneMapping = true;
        hardwareDecodingCodecs = {
          av1 = true;
          h264 = true;
          hevc = true;
          hevc10bit = true;
          vp9 = true;
        };
        hardwareEncodingCodecs = {
          av1 = true;
          hevc = true;
        };
      };
    };

    users.users.jellyfin.extraGroups = [
      "render"
      "video"
    ];
  };
}
