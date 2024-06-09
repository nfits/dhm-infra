{ lib, ... }:

with lib;
{
  networking.useNetworkd = mkDefault true;
}
