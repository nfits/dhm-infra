{ lib, ... }:

with lib;
{
  services.openssh.enable = mkDefault true;
}
