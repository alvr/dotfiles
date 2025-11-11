{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.just
    pkgs.sops
    pkgs.statix
  ];
}
