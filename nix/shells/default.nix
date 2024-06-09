{ pkgs, self, system, ... }:

pkgs.mkShell {
  inherit (self.checks.${system}.pre-commit-check) shellHook;

  nativeBuildInputs = with pkgs; [
    k9s
    kubectl
    kustomize
    nixos-rebuild
    nixpkgs-fmt
    sops
  ];
}
