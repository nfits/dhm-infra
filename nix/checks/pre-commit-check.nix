{
  inputs,
  self,
  lib,
  system,
  ...
}:

inputs.pre-commit-hooks.lib.${system}.run {
  src = self;

  hooks = {
    statix.enable = true;

    nix-fmt = rec {
      enable = true;
      name = "nix-fmt";
      description = "Use the flake formatter";
      package = self.formatter.${system};
      entry = "${lib.getExe package}";
      files = "\\.nix$";
    };
  };
}
