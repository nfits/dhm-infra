{ lib, pkgs, ... }:

with lib;
{
  environment.systemPackages = with pkgs; [
    dfc
    htop
  ];
}
