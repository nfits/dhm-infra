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

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;

          config = import ./nix/nixpkgs-config.nix inputs;

          overlays = [
            (final: prev: {
              crun = prev.crun.overrideAttrs (old: {
                configureFlags = [ "--with-libkrun" ];

                buildInputs = old.buildInputs ++ [ prev.libkrun ];
                nativeBuildInputs = old.nativeBuildInputs ++ [ prev.patchelf ];

                postInstall = ''
                  ln -s crun $out/bin/krun
                '';

                postFixup = ''
                  patchelf --add-rpath ${nixpkgs.lib.makeLibraryPath [ prev.libkrun ]} $out/bin/crun
                '';
              });
              crun-vm = final.callPackage ./nix/packages/crun-vm.nix { };
            })
          ];
        };

        callDir =
          with builtins;
          with pkgs.lib;
          path:
          mapAttrs' (n: _: {
            name = strings.removeSuffix ".nix" n;
            value = pkgs.callPackage "${path}/${n}" { inherit inputs self; };
          }) (filterAttrs (_: t: t == "regular") (readDir path));
      in
      {
        checks = callDir ./nix/checks;
        devShells = callDir ./nix/shells;
        formatter = pkgs.nixfmt-rfc-style;
      }
    )
    // {
      nixosModules =
        with builtins;
        with nixpkgs.lib;
        mapAttrs (n: _: import ./nix/modules/${n}) (
          filterAttrs (_: t: t == "directory") (readDir ./nix/modules)
        );

      nixosConfigurations =
        with builtins;
        with nixpkgs.lib;
        mapAttrs (
          n: _:
          nixpkgs.lib.nixosSystem {
            pkgs = import nixpkgs {
              system = "x86_64-linux";

              config = import ./nix/nixpkgs-config.nix inputs;
            };

            specialArgs = {
              inherit inputs self;
              systemConfigs = mapAttrs (_: e: e.config) self.nixosConfigurations;
            };

            modules = [
              ./nix/systems/${n}
              inputs.sops-nix.nixosModules.default
            ] ++ attrValues self.nixosModules;
          }
        ) (filterAttrs (_: t: t == "directory") (readDir ./nix/systems));
    };
}
