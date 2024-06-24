{ modulesPath, lib, ... }:

with builtins;
with lib;
{
  imports = mapAttrsToList
    (n: _: ./${n})
    (filterAttrs (n: _: n != "default.nix") (readDir ./.)) ++
  [ (modulesPath + "/profiles/qemu-guest.nix") ];

  networking = {
    hostName = "vpn-gateway";
    domain = "orga.dhm-ctf.de";
  };

  # Set defaults
  dhm.isProxmoxVM = true;

  system.stateVersion = "24.05";
}
