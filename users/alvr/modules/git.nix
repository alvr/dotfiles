{ consts, ... }:
{
  dot.hm.programs.git = {
    enable = true;
    name = "Álvaro Salcedo García";
    inherit (consts) email;
  };
}
