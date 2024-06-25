{ lib, ... }:

with lib;
{
  networking = mkDefault { nftables.enable = true; };
}
