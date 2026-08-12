{ inputs, ... }@args:
inputs.nixpkgs.lib.extend (
  self: super: {
    dot = import ./. {
      inherit (args) inputs self;
      lib = self;
    };
  }
)
