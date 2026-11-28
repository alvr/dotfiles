{
  description = "alvr's dotfiles NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    agent-skills.inputs.nixpkgs.follows = "nixpkgs";

    autofirma = {
      url = "github:nix-community/autofirma-nix";
      inputs.flake-parts.follows = "flake-parts";
      inputs.home-manager.follows = "home-manager";
    };

    betterbird.url = "github:TheAnachronism/betterbird-nix";
    betterbird.inputs.nixpkgs.follows = "nixpkgs";

    bootvine.url = "git+https://codeberg.org/wvhulle/bootvine";
    bootvine.inputs.nixpkgs.follows = "nixpkgs";

    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-schemas.follows = "flake-schemas";
        home-manager.follows = "home-manager";
      };
    };

    craftapps.url = "github:olafkfreund/nix-craftapps";
    craftapps.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    determinate.url = "github:DeterminateSystems/determinate";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/0";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hytale-launcher.url = "github:JPyke3/hytale-launcher-nix";
    hytale-launcher.inputs.nixpkgs.follows = "nixpkgs";

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    import-tree.url = "github:denful/import-tree";

    luciole.url = "github:noctalia-dev/luciole/cachix";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix4nvchad.url = "github:nix-community/nix4nvchad";
    nix4nvchad.inputs.nixpkgs.follows = "nixpkgs";

    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";

    packages.url = "path:./packages";
    packages.flake = false;

    secrets.url = "path:./secrets";
    secrets.flake = false;

    skills-caveman.url = "github:JuliusBrussee/caveman";
    skills-caveman.flake = false;

    skills-android.url = "github:android/skills";
    skills-android.flake = false;

    skills-mattpocock.url = "github:mattpocock/skills";
    skills-mattpocock.flake = false;

    skills-ponytail.url = "github:DietrichGebert/ponytail";
    skills-ponytail.flake = false;

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    obsidian-extensions = {
      url = "github:karaolidis/nix-obsidian-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    umbriel.url = "github:noctalia-dev/umbriel/cachix";

    wallpapers.url = "path:./wallpapers";
    wallpapers.flake = false;

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
