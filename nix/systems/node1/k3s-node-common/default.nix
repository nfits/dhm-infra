{ lib, ... }:

with builtins;
with lib;
{
  imports = mapAttrsToList
    (n: _: ./${n})
    (filterAttrs (n: _: n != "default.nix") (readDir ./.));
}
