{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    just
    prek
    sops
    statix
  ];

  shellHook = ''
    prek install
  '';
}
