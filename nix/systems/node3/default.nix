{ modulesPath, lib, ... }:

with builtins;
with lib;
{
  imports = mapAttrsToList
    (n: _: ./${n})
    (filterAttrs (n: _: n != "default.nix") (readDir ./.)) ++
  [ (modulesPath + "/profiles/qemu-guest.nix") ];

  networking = {
    hostName = "node3";
    domain = "cluster.dhm-ctf.de";
  };

  # Set defaults
  dhm.isProxmoxVM = true;

  system.stateVersion = "24.05";
}
