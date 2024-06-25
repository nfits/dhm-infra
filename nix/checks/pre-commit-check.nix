{
  inputs,
  self,
  system,
  ...
}:

inputs.pre-commit-hooks.lib.${system}.run {
  src = self;

  hooks = {
    nixpkgs-fmt.enable = true;
    statix.enable = true;
  };
}
