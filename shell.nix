{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.nil
    pkgs.nixd
    pkgs.just
    pkgs.statix
  ];
}
