{ modulesPath, lib, ... }:

with builtins;
with lib;
{
  imports = mapAttrsToList (n: _: ./${n}) (filterAttrs (n: _: n != "default.nix") (readDir ./.)) ++ [
    ../node1/k3s-node-common
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking = {
    hostName = "node4";
    domain = "cluster.dhm-ctf.de";
  };

  # Set defaults
  dhm.isProxmoxVM = true;

  system.stateVersion = "24.05";
}
