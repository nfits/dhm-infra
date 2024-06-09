{
  description = "Infrastructure of the Deutsche Hacking Meisterschaft";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };

    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, flake-utils, nixpkgs, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          callDir = with builtins; with pkgs.lib; path: mapAttrs'
            (n: _: {
              name = strings.removeSuffix ".nix" n;
              value = pkgs.callPackage "${path}/${n}" { inherit inputs self; };
            })
            (filterAttrs (_: t: t == "regular") (readDir path));
        in
        {
          checks = callDir ./nix/checks;
          devShells = callDir ./nix/shells;
        }) // {
      nixosModules = with builtins; with nixpkgs.lib; mapAttrs
        (n: _: import ./nix/modules/${n})
        (filterAttrs (_: t: t == "directory") (readDir ./nix/modules));

      nixosConfigurations = with builtins; with nixpkgs.lib; mapAttrs
        (n: _: nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          specialArgs = {
            inherit inputs self;
            systemConfigs = mapAttrs (_: e: e.config) self.nixosConfigurations;
          };

          modules = [
            ./nix/systems/${n}
            inputs.sops-nix.nixosModules.default
          ] ++ attrValues self.nixosModules;
        })
        (filterAttrs (_: t: t == "directory") (readDir ./nix/systems));
    };
}
