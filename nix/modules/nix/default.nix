{ lib, pkgs, ... }:

with builtins;
with lib;
{
  imports = mapAttrsToList (n: _: ./${n}) (
    filterAttrs (n: t: n != "default.nix" && t == "regular") (readDir ./.)
  );

  nix = mkDefault {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";

    gc = {
      automatic = true;

      dates = "weekly";
      options = "--delete-older-than 7d";
      persistent = true;
    };
  };
}
