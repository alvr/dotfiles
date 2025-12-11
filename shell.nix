{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    just
    prek
    rclone
    sops
    statix
  ];

  shellHook = ''
    prek install
  '';
}
