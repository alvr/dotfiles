{ nixpkgs-unstable }:
(final: prev: {
  unstable = import nixpkgs-unstable {
    inherit (final) system;
    config.allowUnfree = true;
  };
})
