{ nixpkgs, ... }:

{
  allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
    # Needed for helm-secrets
    "vault"
  ];
}
