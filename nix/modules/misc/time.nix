{ lib, ... }:

with lib;
{
  config = mkDefault { time.timeZone = "Europe/Berlin"; };
}
