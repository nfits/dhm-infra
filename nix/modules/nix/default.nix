{ lib, pkgs, inputs, ... }:

with builtins;
with lib;
{
  imports = mapAttrsToList
    (n: _: ./${n})
    (filterAttrs (n: t: n != "default.nix" && t == "regular") (readDir ./.));

  nix = mkDefault {
    package = pkgs.nixFlakes;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
      (lib.filterAttrs (_: lib.isType "flake")) inputs
    );

    gc = {
      automatic = true;

      dates = "weekly";
      options = "--delete-older-than 7d";
      persistent = true;
    };
  };
}
