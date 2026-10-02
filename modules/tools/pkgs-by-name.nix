{ inputs, withSystem, ... }:
{
  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  perSystem = {
    pkgsDirectory = inputs.packages;
  };

  flake.overlays.default =
    _final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:
      config.packages // { local = config.packages; }
    )
    // {
      # WORKAROUND for Podman >= 5.8.7 (CVE-2025-11395 hardening) / Docker 29.7.0
      # Backport of https://gitea.com/gitea/runner/pulls/1130 adapted to Forgejo's
      # Upstream daemon bug: https://github.com/moby/moby/issues/53258
      forgejo-runner = prev.forgejo-runner.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [ ./forgejo-runner-var-run-symlink.patch ];
      });
    };
}
