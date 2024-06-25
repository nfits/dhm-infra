{ lib, pkgs, ... }:

with builtins;
with lib;
{
  imports = mapAttrsToList (n: _: ./${n}) (
    filterAttrs (n: t: n != "default.nix" && t == "regular") (readDir ./.)
  );
}
