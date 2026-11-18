{ inputs, lib, ... }:
let
  skillInputs = lib.filterAttrs (name: _: lib.hasPrefix "skills-" name) inputs;
in
{
  flake.modules.homeManager.ai-skills = {
    imports = [ inputs.agent-skills.homeManagerModules.default ];

    programs.agent-skills = {
      enable = true;

      sources = lib.mapAttrs' (
        name: source:
        lib.nameValuePair (lib.removePrefix "skills-" name) {
          path = source;
          subdir = if builtins.pathExists "${source}/skills" then "skills" else ".";
          idPrefix = lib.removePrefix "skills-" name;
        }
      ) skillInputs;

      skills.enableAll = true;

      targets.agents = {
        enable = true;
        dest = ".agents/skills";
        structure = "link";
      };
    };
  };
}
