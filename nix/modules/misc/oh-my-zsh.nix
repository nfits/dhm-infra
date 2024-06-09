{ lib, pkgs, ... }:

with lib;
{
  programs.zsh = mkDefault {
    enable = true;
    autosuggestions.enable = true;

    ohMyZsh = {
      enable = true;
      theme = "agnoster";
    };
  };
}
