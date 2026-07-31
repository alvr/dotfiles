{ ... }:
(final: prev: {
  grimmory = final.callPackage ../packages/grimmory/default.nix { };
  reactflux = final.callPackage ../packages/reactflux.nix { };
  transmission-web = final.callPackage ../packages/transmission-web { };
})
