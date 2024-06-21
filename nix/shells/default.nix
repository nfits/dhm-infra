{ pkgs, self, system, ... }:

pkgs.mkShell {
  inherit (self.checks.${system}.pre-commit-check) shellHook;

  nativeBuildInputs = with pkgs; [
    (wrapHelm kubernetes-helm {
      plugins = with kubernetes-helmPlugins; [ helm-secrets ];
    })

    k9s
    kubectl
    kustomize
    kustomize-sops
    nixos-rebuild
    nixpkgs-fmt
    sops
    sshuttle
  ];
}
